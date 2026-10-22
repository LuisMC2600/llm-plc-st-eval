"""
Verificador de integridad de prompts — control de reproducibilidad.
Tesis: LLMs como Asistentes de Programacion PLC en la Academia (FIE-UTP).

POR QUE EXISTE ESTE SCRIPT
    tasks.json es un producto derivado de generar_prompts.py. Cada vez que se
    regenera (por ejemplo, para agregar tareas nuevas al banco) se reescribe el
    archivo COMPLETO, incluidas las tareas ya ejecutadas. Si la regeneracion
    altera aunque sea un caracter del enunciado de una tarea ya corrida, los
    datos del piloto (data/raw) dejan de ser comparables con los del
    experimento definitivo y con el articulo ya publicado.

    Este script compara el hash de cada prompt de tasks.json contra el
    hash_prompt registrado en el log de un experimento ya ejecutado, que es
    dato primario y no se toca.

USO
    python verificar_hashes.py                          # vs data/raw/log.jsonl (piloto)
    python verificar_hashes.py --log ../data/definitivo/log.jsonl
    python verificar_hashes.py --snapshot linea_base.json   # guarda hashes actuales
    python verificar_hashes.py --comparar linea_base.json   # compara contra ese snapshot

Codigo de salida: 0 si todo coincide, 1 si hay cualquier discrepancia.
"""

from __future__ import annotations
import argparse
import hashlib
import json
import sys
from collections import defaultdict
from pathlib import Path


def hash_prompt(prompt: str) -> str:
    """Replica exacta de runner.hash_prompt. Si cambia alla, cambiar aca."""
    return hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:16]


def _verificar_paridad_con_runner() -> None:
    """Comprueba que la funcion de hash no se haya desincronizado de runner.py."""
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        import runner  # noqa: F401
    except Exception:
        return  # runner no importable (falta pyyaml, etc.): no es fatal aqui
    sonda = "prueba de paridad"
    if runner.hash_prompt(sonda) != hash_prompt(sonda):
        print("[FATAL] hash_prompt de este script difiere del de runner.py.",
              file=sys.stderr)
        sys.exit(1)


def hashes_de_tasks(ruta: Path) -> dict[str, str]:
    """Devuelve {'<tarea>|<estrategia>': hash} para todo tasks.json."""
    with open(ruta, encoding="utf-8") as f:
        tareas = json.load(f)["tareas"]
    out: dict[str, str] = {}
    for t in tareas:
        for estrategia, prompt in (t.get("prompts") or {}).items():
            if prompt:
                out[f"{t['id']}|{estrategia}"] = hash_prompt(prompt)
    return out


def hashes_de_log(ruta: Path) -> dict[str, set[str]]:
    """Devuelve {'<tarea>|<estrategia>': {hashes observados}} desde el log JSONL."""
    out: dict[str, set[str]] = defaultdict(set)
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            linea = linea.strip()
            if not linea:
                continue
            r = json.loads(linea)
            out[f"{r['tarea']}|{r['estrategia']}"].add(r["hash_prompt"])
    return out


def comparar(actuales: dict[str, str], referencia: dict[str, set[str]],
             fuente: str) -> int:
    comunes = sorted(set(actuales) & set(referencia.keys()))
    if not comunes:
        print(f"[AVISO] Ninguna clave en comun con {fuente}. Nada que verificar.")
        return 0

    iguales, distintos, ambiguos = [], [], []
    for clave in comunes:
        observados = referencia[clave]
        if len(observados) > 1:
            ambiguos.append((clave, observados))
        elif actuales[clave] in observados:
            iguales.append(clave)
        else:
            distintos.append((clave, actuales[clave], next(iter(observados))))

    print(f"Referencia: {fuente}")
    print(f"Pares tarea|estrategia comparados: {len(comunes)}")
    print(f"  coinciden : {len(iguales)}")
    print(f"  difieren  : {len(distintos)}")
    print(f"  ambiguos  : {len(ambiguos)}  (mas de un hash en la referencia)")

    solo_en_tasks = sorted(set(actuales) - set(referencia.keys()))
    if solo_en_tasks:
        print(f"\nPresentes en tasks.json y ausentes en la referencia "
              f"({len(solo_en_tasks)}) — normal si son tareas nuevas:")
        print("  " + ", ".join(solo_en_tasks))

    if ambiguos:
        print("\n[ALERTA] Claves con varios hashes en la referencia:")
        for clave, hs in ambiguos:
            print(f"  {clave}: {sorted(hs)}")

    if distintos:
        print("\n[FALLO] El enunciado de estas tareas CAMBIO respecto al dato primario.")
        print("        No ejecutar ni publicar hasta resolverlo.\n")
        for clave, ahora, antes in distintos:
            print(f"  {clave}: ahora={ahora}  dato_primario={antes}")
        return 1

    print("\n[OK] Integridad confirmada: ningun enunciado ya ejecutado cambio.")
    return 0


def main() -> None:
    aqui = Path(__file__).parent
    ap = argparse.ArgumentParser()
    ap.add_argument("--tareas", default=str(aqui / "tasks.json"))
    ap.add_argument("--log", default=str(aqui / ".." / "data" / "raw" / "log.jsonl"),
                    help="Log JSONL de un experimento ya ejecutado (dato primario)")
    ap.add_argument("--snapshot", metavar="ARCHIVO",
                    help="Guarda los hashes actuales de tasks.json y termina")
    ap.add_argument("--comparar", metavar="ARCHIVO",
                    help="Compara tasks.json contra un snapshot previo")
    args = ap.parse_args()

    _verificar_paridad_con_runner()
    actuales = hashes_de_tasks(Path(args.tareas))
    print(f"tasks.json: {len(actuales)} prompts "
          f"({len({c.split('|')[0] for c in actuales})} tareas)\n")

    if args.snapshot:
        Path(args.snapshot).write_text(
            json.dumps(actuales, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"[OK] Snapshot guardado en {args.snapshot}")
        sys.exit(0)

    if args.comparar:
        previo = json.loads(Path(args.comparar).read_text(encoding="utf-8"))
        sys.exit(comparar(actuales, {k: {v} for k, v in previo.items()},
                          f"snapshot {args.comparar}"))

    ruta_log = Path(args.log)
    if not ruta_log.exists():
        print(f"[AVISO] No existe el log {ruta_log}. Nada que comparar.")
        sys.exit(0)
    sys.exit(comparar(actuales, hashes_de_log(ruta_log), str(ruta_log)))


if __name__ == "__main__":
    main()
