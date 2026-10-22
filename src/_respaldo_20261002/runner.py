"""
Orquestador experimental — Fase 4 del plan de trabajo (tareas 4.1–4.3).
Recorre modelos × tareas × estrategias × N ejecuciones, guarda cada respuesta
como archivo .st y registra los metadatos en un log JSONL (dato primario).

Uso:
    python runner.py                # ejecuta todo lo pendiente
    python runner.py --dry-run      # muestra qué haría, sin llamar APIs (tarea 3.4)

Propiedades de diseño:
- Idempotente: si el archivo de una ejecución ya existe, se salta.
  Se puede reanudar tras un corte sin duplicar llamadas ni gastar tokens.
- Reintentos con backoff exponencial ante errores transitorios de API.
- Ningún parámetro experimental está en el código: todo viene de config.yaml.
"""

from __future__ import annotations
import argparse
import datetime as dt
import hashlib
import json
import sys
import time
from pathlib import Path

import yaml

from clients import crear_cliente


def cargar_config(ruta: str = "config.yaml") -> dict:
    with open(ruta, encoding="utf-8") as f:
        return yaml.safe_load(f)


def cargar_tareas(ruta: str) -> list[dict]:
    with open(ruta, encoding="utf-8") as f:
        return json.load(f)["tareas"]


def hash_prompt(prompt: str) -> str:
    """Hash del prompt: prueba de que todos los modelos recibieron el mismo texto."""
    return hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:16]


def registrar(log_path: Path, registro: dict) -> None:
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(registro, ensure_ascii=False) + "\n")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true",
                    help="Lista las ejecuciones pendientes sin llamar a las APIs")
    ap.add_argument("--config", default="config.yaml",
                    help="Archivo de configuración (por defecto config.yaml)")
    args = ap.parse_args()

    cfg = cargar_config(args.config)
    tareas = cargar_tareas(cfg["rutas"]["tareas"])
    repo = Path(cfg["rutas"]["repositorio"])
    log_path = Path(cfg["rutas"]["log"])
    repo.mkdir(parents=True, exist_ok=True)

    gen = cfg["generacion"]
    n_ejec = cfg["experimento"]["ejecuciones_por_tarea"]
    estrategias = cfg["experimento"]["estrategias"]

    # Subconjunto de tareas (piloto). Lista vacía o ausente = banco completo.
    filtro = cfg["experimento"].get("filtro_tareas") or []
    if filtro:
        tareas = [t for t in tareas if t["id"] in filtro]
        faltan = set(filtro) - {t["id"] for t in tareas}
        if faltan:
            print(f"[AVISO] IDs del filtro que no existen en el banco: {sorted(faltan)}",
                  file=sys.stderr)
        print(f"Filtro activo: {len(tareas)} tareas -> {[t['id'] for t in tareas]}")

    pendientes, hechas = 0, 0

    for m in cfg["modelos"]:
        cliente = None  # se crea perezosamente solo si hay trabajo para el modelo
        for tarea in tareas:
            for estrategia in estrategias:
                prompt = tarea["prompts"].get(estrategia)
                if not prompt:
                    continue  # tarea sin prompt para esta estrategia (aún)
                for n in range(1, n_ejec + 1):
                    destino = (repo / m["id"].replace(":", "_") / tarea["id"]
                               / estrategia / f"ejec_{n}.st")
                    if destino.exists():
                        hechas += 1
                        continue
                    pendientes += 1
                    if args.dry_run:
                        print(f"[dry-run] {m['id']} | {tarea['id']} | "
                              f"{estrategia} | ejec {n}")
                        continue

                    if cliente is None:
                        cliente = crear_cliente(
                            m["proveedor"], m["id"],
                            gen["temperature"], gen["max_tokens"])

                    # --- llamada con reintentos y backoff exponencial ---
                    r_cfg = cfg["reintentos"]
                    for intento in range(1, r_cfg["max_intentos"] + 1):
                        try:
                            g = cliente.generate(prompt)
                            break
                        except Exception as e:  # error de red / rate limit
                            if intento == r_cfg["max_intentos"]:
                                print(f"[ERROR] {m['id']}|{tarea['id']}|{n}: {e}",
                                      file=sys.stderr)
                                g = None
                                break
                            espera = r_cfg["espera_base_s"] * 2 ** (intento - 1)
                            print(f"  reintento {intento} en {espera}s ({e})")
                            time.sleep(espera)
                    if g is None:
                        continue

                    # --- persistencia: archivo .st + metadatos JSONL ---
                    destino.parent.mkdir(parents=True, exist_ok=True)
                    destino.write_text(g.texto, encoding="utf-8")
                    registrar(log_path, {
                        "timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
                        "modelo_config": m["id"],
                        "modelo_reportado": g.modelo_reportado,
                        "proveedor": m["proveedor"],
                        "tarea": tarea["id"],
                        "nivel": tarea["nivel"],
                        "tipo": tarea["tipo"],
                        "estrategia": estrategia,
                        "ejecucion": n,
                        "temperature": gen["temperature"],
                        "max_tokens": gen["max_tokens"],
                        "hash_prompt": hash_prompt(prompt),
                        "tokens_entrada": g.tokens_entrada,
                        "tokens_salida": g.tokens_salida,
                        "latencia_s": g.latencia_s,
                        "archivo": str(destino),
                    })
                    print(f"[ok] {m['id']} | {tarea['id']} | {estrategia} | "
                          f"ejec {n} ({g.latencia_s}s)")

    print(f"\nResumen: {hechas} ya existían, {pendientes} "
          f"{'pendientes' if args.dry_run else 'procesadas'}.")


if __name__ == "__main__":
    main()
