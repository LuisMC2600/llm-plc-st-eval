# -*- coding: utf-8 -*-
"""Prepara la evaluacion manual A CIEGAS de C1, C5, C6 (diagnostico) y C2 (requisito ambiguo).

Lee las 96 respuestas de data/definitivo (solo lectura), les asigna un codigo aleatorio,
las baraja dentro de cada tarea y elige la submuestra del segundo evaluador (6 por tarea:
una por modelo mas dos al azar). Semilla fija: el resultado es reproducible.
Escribe en evaluacion_manual/:
  _SELLADO_asignacion_codigos.csv   codigo <-> modelo/estrategia/ejecucion. NO ABRIR hasta terminar de calificar.
  paquete_fichas.json               respuestas codificadas (sin modelo) para construir las fichas.
Uso: python evaluacion_manual/preparar_fichas.py   (desde llm-plc-st-eval)"""
import csv, json, os, random, hashlib
SEMILLA = 20261007
TAREAS = ["C1", "C5", "C6", "C2"]
MODELOS = ["claude-sonnet-4-6", "gemini-3.1-pro-preview", "gpt-4o-2024-08-06", "qwen2.5-coder_14b"]
rng = random.Random(SEMILLA)
enun = {t["id"]: t for t in json.load(open("src/tasks.json", encoding="utf-8"))["tareas"]}
log = {}
for l in open("data/definitivo/log.jsonl", encoding="utf-8"):
    if l.strip():
        r = json.loads(l); log[(r["modelo_config"].replace(":", "_"), r["tarea"], r["estrategia"], r["ejecucion"])] = r
numeros = list(range(101, 101 + 24 * len(TAREAS))); rng.shuffle(numeros)
filas, paquete = [], {"semilla": SEMILLA, "tareas": {}}
for t in TAREAS:
    items = []
    for m in MODELOS:
        for e in ("zero_shot", "few_shot"):
            for n in (1, 2, 3):
                ruta = os.path.join("data", "definitivo", m, t, e, "ejec_%d.st" % n)
                items.append({"modelo": m, "estrategia": e, "ejec": n, "ruta": ruta, "texto": open(ruta, encoding="utf-8").read()})
    rng.shuffle(items)
    for it in items: it["codigo"] = "%s-%d" % (t, numeros.pop())
    sub = set()
    for m in MODELOS: sub.add(rng.choice([it["codigo"] for it in items if it["modelo"] == m]))
    resto = [it["codigo"] for it in items if it["codigo"] not in sub]; sub.update(rng.sample(resto, 2))
    paquete["tareas"][t] = {"titulo": enun[t]["titulo"], "enunciado": enun[t]["prompts"]["zero_shot"],
                            "respuestas": [{"codigo": it["codigo"], "texto": it["texto"], "evaluador2": it["codigo"] in sub} for it in items]}
    for orden, it in enumerate(items, 1):
        lg = log[(it["modelo"], t, it["estrategia"], it["ejec"])]
        filas.append({"codigo": it["codigo"], "tarea": t, "orden_en_ficha": orden, "evaluador2": int(it["codigo"] in sub),
                      "modelo": it["modelo"], "estrategia": it["estrategia"], "ejec": it["ejec"], "archivo": it["ruta"].replace(os.sep, "/"),
                      "truncada": int(bool(lg.get("truncada"))), "sha256_texto": hashlib.sha256(it["texto"].encode("utf-8")).hexdigest()[:16]})
with open("evaluacion_manual/_SELLADO_asignacion_codigos.csv", "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.DictWriter(fh, fieldnames=list(filas[0].keys())); w.writeheader(); w.writerows(filas)
json.dump(paquete, open("evaluacion_manual/paquete_fichas.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("Respuestas: %d | submuestra evaluador 2: %d | codigos unicos: %d" % (len(filas), sum(f["evaluador2"] for f in filas), len({f["codigo"] for f in filas})))
