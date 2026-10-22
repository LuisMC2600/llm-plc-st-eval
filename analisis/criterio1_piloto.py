# -*- coding: utf-8 -*-
"""Criterio 1 (correccion funcional) del piloto, medido con los 12 harnesses
verificados en CODESYS V3.5 SP22 P3 (MainTask 10 ms). Ejecutable en Spyder por celdas."""
#%% Carga y clasificacion
import csv, collections, math
from scipy.stats import binomtest
import sys
# v2 = filas de I6 re-simuladas con el extractor v2 (regla por patron). Para la v1 pasar la ruta como argumento.
CSV = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].endswith(".csv") else r"data/results_codesys/harness_respuestas_piloto_10ms_v2.csv"
R = list(csv.DictReader(open(CSV, encoding="utf-8-sig")))
def categoria(r):
    if r["compila"] == "1":
        return "PASA" if r["veredicto"] == "1" else "FALLA_LOGICA"
    n = r["nota"]
    if n.startswith("interfaz"): return "EXTRACCION"
    if "no es ninguna entrada" in n: return "INTERFAZ_NO_CONFORME"
    return "NO_COMPILA"
for r in R:
    r["modelo"], r["estrategia"], r["ejec"] = r["id"].split("|")
    r["cat"] = categoria(r); r["ok"] = int(r["cat"] == "PASA")
def wilson(k, n, z=1.959964):
    p = k / n; d = 1 + z*z/n; c = (p + z*z/(2*n)) / d; h = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n)) / d
    return c - h, c + h
def mcnemar(pares):
    b = sum(1 for a, c in pares if a == 1 and c == 0); c_ = sum(1 for a, c in pares if a == 0 and c == 1)
    p = binomtest(b, b + c_, 0.5).pvalue if b + c_ else 1.0
    return b, c_, p
#%% Tasas globales
print("Categorias:", dict(collections.Counter(r["cat"] for r in R)))
k = sum(r["ok"] for r in R); lo, hi = wilson(k, len(R))
print("Global: %d/%d = %.1f %% [%.1f; %.1f]" % (k, len(R), 100*k/len(R), 100*lo, 100*hi))
for g in [("modelo",), ("modelo", "estrategia")]:
    grupos = collections.defaultdict(list)
    for r in R: grupos[tuple(r[x] for x in g)].append(r["ok"])
    for key, v in sorted(grupos.items()):
        lo, hi = wilson(sum(v), len(v))
        print("  %-40s %2d/%2d = %5.1f %% [%5.1f; %5.1f]" % (" | ".join(key), sum(v), len(v), 100*sum(v)/len(v), 100*lo, 100*hi))
#%% McNemar: zero vs few por modelo (pareado por tarea x ejecucion) y modelo vs modelo
idx = {(r["modelo"], r["tarea"], r["estrategia"], r["ejec"]): r["ok"] for r in R}
modelos = sorted({r["modelo"] for r in R}); tareas = sorted({r["tarea"] for r in R})
for m in modelos:
    pares = [(idx[(m, t, "zero_shot", e)], idx[(m, t, "few_shot", e)]) for t in tareas for e in ("ejec_1", "ejec_2", "ejec_3")]
    b, c, p = mcnemar(pares); print("%s: solo zero=%d, solo few=%d, McNemar exacto p=%.3f" % (m, b, c, p))
pares = [(idx[(modelos[0], t, s, e)], idx[(modelos[1], t, s, e)]) for t in tareas for s in ("zero_shot", "few_shot") for e in ("ejec_1", "ejec_2", "ejec_3")]
b, c, p = mcnemar(pares); print("%s vs %s: solo 1.o=%d, solo 2.o=%d, McNemar exacto p=%.3f" % (modelos[0], modelos[1], b, c, p))
#%% Tabla por tarea (aciertos de 3)
print("\n%-5s" % "tarea" + "".join("%-22s" % (m[:10] + "/" + s[:4]) for m in modelos for s in ("zero_shot", "few_shot")))
for t in tareas:
    print("%-5s" % t + "".join("%-22s" % sum(idx[(m, t, s, e)] for e in ("ejec_1", "ejec_2", "ejec_3")) for m in modelos for s in ("zero_shot", "few_shot")))
#%% Categoria de fallo por modelo
for m in modelos:
    print(m, dict(collections.Counter(r["cat"] for r in R if r["modelo"] == m)))
