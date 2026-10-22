# -*- coding: utf-8 -*-
"""Consistencia entre las 3 ejecuciones de cada celda (modelo x tarea x estrategia).
Mide la 'confiabilidad' en sentido de repetibilidad: con el mismo prompt y los mismos
parametros, ¿el modelo da el mismo resultado? Usa data/results/tabla_definitivo.csv
(criterios 1 y 2, 600 respuestas de codigo) y los textos de data/definitivo (720).
Ejecutable en Spyder por celdas, desde la carpeta llm-plc-st-eval."""
#%% Carga
import csv, collections, hashlib, os, math
T = list(csv.DictReader(open("data/results/tabla_definitivo.csv", encoding="utf-8-sig")))
MODELOS = ["gemini-3.1-pro-preview", "claude-sonnet-4-6", "gpt-4o-2024-08-06", "qwen2.5-coder_14b"]
def wilson(k, n, z=1.959964):
    if n == 0: return (0.0, 0.0)
    p = k / n; d = 1 + z*z/n; c = (p + z*z/(2*n)) / d; h = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n)) / d
    return 100*(c - h), 100*(c + h)
celdas = collections.defaultdict(list)
for r in T: celdas[(r["modelo"], r["tarea"], r["estrategia"])].append(r)
assert all(len(v) == 3 for v in celdas.values()) and len(celdas) == 200
#%% Repetibilidad del resultado (criterios 1 y 2)
def repetibilidad(campo, titulo):
    print("\n===== %s: resultado de las 3 ejecuciones por celda (50 celdas por modelo) =====" % titulo)
    print("  %-26s %6s %6s %6s %6s | %-22s | %s" % ("modelo", "3/3", "2/3", "1/3", "0/3", "celdas unanimes", "si acierta alguna vez, acierta las 3"))
    filas = []
    for m in MODELOS + ["TODOS"]:
        c = collections.Counter(sum(int(r[campo]) for r in v) for k, v in celdas.items() if m in ("TODOS", k[0]))
        n = sum(c.values()); una = c[3] + c[0]; alguna = c[3] + c[2] + c[1]
        lo, hi = wilson(una, n); lo2, hi2 = wilson(c[3], alguna)
        print("  %-26s %6d %6d %6d %6d | %3d/%3d = %5.1f %% | %3d/%3d = %5.1f %% [%4.1f; %4.1f]" % (m, c[3], c[2], c[1], c[0], una, n, 100*una/n, c[3], alguna, 100*c[3]/alguna if alguna else 0, lo2, hi2))
        filas.append([titulo, m, c[3], c[2], c[1], c[0], n])
    return filas
F = repetibilidad("c2_compila", "CRITERIO 2 (compila)") + repetibilidad("c1_pasa", "CRITERIO 1 (pasa el harness)")
with open("data/results/consistencia_definitivo.csv", "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.writer(fh); w.writerow(["criterio", "modelo", "celdas_3de3", "celdas_2de3", "celdas_1de3", "celdas_0de3", "celdas"]); w.writerows(F)
#%% Celdas mixtas del criterio 1 (donde el resultado depende de la ejecucion)
print("\n===== Criterio 1: celdas con resultado mixto (1/3 o 2/3) =====")
for m in MODELOS:
    mix = sorted("%s-%s(%d/3)" % (k[1], "Z" if k[2] == "zero_shot" else "F", sum(int(r["c1_pasa"]) for r in v)) for k, v in celdas.items() if k[0] == m and 0 < sum(int(r["c1_pasa"]) for r in v) < 3)
    print("  %-26s %2d: %s" % (m, len(mix), " ".join(mix)))
#%% Determinismo del texto: ¿cuantas respuestas distintas hay entre las 3 ejecuciones? (720 respuestas)
print("\n===== Texto de la respuesta: respuestas distintas entre las 3 ejecuciones (60 celdas por modelo) =====")
print("  %-26s %10s %10s %10s" % ("modelo", "3 iguales", "2 iguales", "3 distintas"))
for m in MODELOS:
    c = collections.Counter()
    base = os.path.join("data", "definitivo", m)
    for t in sorted(os.listdir(base)):
        for e in ("zero_shot", "few_shot"):
            hs = {hashlib.sha256(open(os.path.join(base, t, e, "ejec_%d.st" % n), "rb").read()).hexdigest() for n in (1, 2, 3)}
            c[len(hs)] += 1
    print("  %-26s %10d %10d %10d" % (m, c[1], c[2], c[3]))
