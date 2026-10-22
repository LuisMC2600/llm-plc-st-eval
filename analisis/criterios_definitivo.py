# -*- coding: utf-8 -*-
"""Criterios 1 y 2 del experimento definitivo (720 ejecuciones, 4 modelos).

Criterio 2: la respuesta compila sola en CODESYS V3.5 SP22 P3 (compilar_lote_sp22.py).
            Se calcula sobre las 600 respuestas de tareas de codigo (T1 y T4).
Criterio 1: la respuesta pasa el harness de su tarea (simular_lote_sp22.py, ciclo 10 ms).
            Se calcula sobre las 600 respuestas de las 25 tareas de codigo: 23 con harness
            propio mas C7 y C8, que usan los harnesses de B3 y B2 (misma interfaz y conducta).
Analisis principal ESTRICTO: las respuestas se evaluan tal como se entregaron.
Sensibilidad: S1 sin la tarea A1 (INC-33, variable `dt`); S2 con la normalizacion de
`END_STRUCT;` (INC-34), solo si existen los CSV de data/results_codesys/sens_*.csv.
Ejecutable en Spyder por celdas, desde la carpeta llm-plc-st-eval."""
#%% Carga y tabla unificada
import csv, json, math, collections, itertools, os
from scipy.stats import binomtest, wilcoxon
RC = "data/results_codesys/"
leer = lambda p: list(csv.DictReader(open(p, encoding="latin-1")))
TAREAS = {t["id"]: t for t in json.load(open("src/tasks.json", encoding="utf-8"))["tareas"]}
MODELOS = ["gemini-3.1-pro-preview", "claude-sonnet-4-6", "gpt-4o-2024-08-06", "qwen2.5-coder_14b"]
ESTR = ["zero_shot", "few_shot"]; EJEC = ["ejec_1", "ejec_2", "ejec_3"]
ARCH = {"gemini-3.1-pro-preview": "definitivo_gemini.csv", "claude-sonnet-4-6": "definitivo_claude.csv",
        "gpt-4o-2024-08-06": "definitivo_gpt4o.csv", "qwen2.5-coder_14b": "definitivo_qwen.csv"}
def clave_ejec(x): return x if str(x).startswith("ejec_") else "ejec_%s" % x
COMP = {(r["modelo"], r["tarea"], r["estrategia"], clave_ejec(r["ejecucion"])): r for r in leer(RC + "compilacion_definitivo_v2.csv")}
SIM = {}
for m in MODELOS:
    for r in leer(RC + ARCH[m]):
        mo, es, ej = r["id"].split("|"); SIM[(mo, r["tarea"], es, ej)] = r
# C7 y C8 (conversion LD->ST) se simulan con los harnesses verificados de B3 y B2 (HARNESS_DE).
if os.path.exists(RC + "definitivo_c7c8.csv"):
    for r in leer(RC + "definitivo_c7c8.csv"):
        mo, es, ej = r["id"].split("|"); SIM[(mo, r["tarea"], es, ej)] = r
def categoria(c, s):
    """PASA / FALLA_LOGICA / INTERFAZ_NO_CONFORME / NO_COMPILA (sin harness: solo criterio 2)."""
    if s is None: return ""
    if s["veredicto"] == "1": return "PASA"
    if s["veredicto"] == "2": return "FALLA_LOGICA"
    if s["compila"] == "0": return "NO_COMPILA" if c["compila"] == "0" else "INTERFAZ_NO_CONFORME"
    return "REVISAR"
T = []
for k, c in sorted(COMP.items()):
    mo, ta, es, ej = k; tipo = TAREAS[ta]["tipo"]
    if tipo[:2] not in ("T1", "T4"): continue
    s = SIM.get(k); et = c.get("errores_texto", "")
    T.append({"modelo": mo, "tarea": ta, "nivel": TAREAS[ta]["nivel"], "tipo": tipo, "estrategia": es, "ejec": ej,
              "c2_compila": int(c["compila"] == "1"), "con_harness": int(s is not None),
              "c1_categoria": categoria(c, s), "c1_pasa": "" if s is None else int(s["veredicto"] == "1"),
              "pasos_fallidos": "" if s is None else s["pasos_fallidos"], "pou": "" if s is None else s.get("pou", ""),
              "caso_dt": int("'dt'" in et), "caso_end_struct": int("END_TYPE' en lugar de ';'" in et),
              "n_errores": c["errores"], "errores_texto": et})
os.makedirs("data/results", exist_ok=True)
with open("data/results/tabla_definitivo.csv", "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.DictWriter(fh, fieldnames=list(T[0].keys())); w.writeheader(); w.writerows(T)
H = [r for r in T if r["con_harness"]]
print("Respuestas de codigo: %d | con harness: %d | REVISAR: %d" % (len(T), len(H), sum(r["c1_categoria"] == "REVISAR" for r in T)))
def wilson(k, n, z=1.959964):
    p = k / n; d = 1 + z*z/n; c = (p + z*z/(2*n)) / d; h = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n)) / d
    return 100*(c - h), 100*(c + h)
def tasa(v):
    k, n = sum(v), len(v); lo, hi = wilson(k, n); return "%3d/%3d = %5.1f %% [%5.1f; %5.1f]" % (k, n, 100*k/n, lo, hi)
def mcnemar(pares):
    b = sum(1 for a, c in pares if a == 1 and c == 0); c_ = sum(1 for a, c in pares if a == 0 and c == 1)
    return b, c_, (binomtest(b, b + c_, 0.5).pvalue if b + c_ else 1.0)
def holm(ps):
    orden = sorted(range(len(ps)), key=lambda i: ps[i]); adj = [0.0]*len(ps); ant = 0.0
    for j, i in enumerate(orden):
        ant = max(ant, min(1.0, (len(ps) - j) * ps[i])); adj[i] = ant
    return adj
def informe(filas, campo, titulo, tareas=None):
    F = [r for r in filas if tareas is None or r["tarea"] in tareas]
    print("\n===== %s (n = %d) =====" % (titulo, len(F)))
    print("  %-34s %s" % ("GLOBAL", tasa([r[campo] for r in F])))
    for m in MODELOS:
        print("  %-34s %s" % (m, tasa([r[campo] for r in F if r["modelo"] == m])))
    for m in MODELOS:
        for e in ESTR:
            print("  %-34s %s" % (m[:22] + " | " + e, tasa([r[campo] for r in F if r["modelo"] == m and r["estrategia"] == e])))
    for n in ["Basico", "Intermedio", "Avanzado", "Complementaria"]:
        v = [r[campo] for r in F if r["nivel"] == n]
        if v: print("  %-34s %s" % ("nivel " + n, tasa(v)))
    idx = {(r["modelo"], r["tarea"], r["estrategia"], r["ejec"]): r[campo] for r in F}
    ts = sorted({r["tarea"] for r in F})
    print("  -- zero-shot vs few-shot por modelo (McNemar exacto, pareado por tarea x ejecucion; Wilcoxon por tarea)")
    for m in MODELOS:
        b, c, p = mcnemar([(idx[(m, t, "zero_shot", e)], idx[(m, t, "few_shot", e)]) for t in ts for e in EJEC])
        dz = [sum(idx[(m, t, "few_shot", e)] for e in EJEC) - sum(idx[(m, t, "zero_shot", e)] for e in EJEC) for t in ts]
        pw = wilcoxon(dz).pvalue if any(dz) else 1.0
        print("     %-26s solo zero=%2d  solo few=%2d  p=%.3f | Wilcoxon p=%.3f" % (m, b, c, p, pw))
    print("  -- modelo vs modelo (McNemar exacto, pareado por tarea x estrategia x ejecucion; Holm sobre 6 comparaciones)")
    pares_m = list(itertools.combinations(MODELOS, 2)); res = []
    for a, b_ in pares_m:
        x, y, p = mcnemar([(idx[(a, t, s, e)], idx[(b_, t, s, e)]) for t in ts for s in ESTR for e in EJEC])
        d = [sum(idx[(a, t, s, e)] for e in EJEC) - sum(idx[(b_, t, s, e)] for e in EJEC) for t in ts for s in ESTR]
        res.append((a, b_, x, y, p, wilcoxon(d).pvalue if any(d) else 1.0))
    adj = holm([r[4] for r in res])
    for (a, b_, x, y, p, pw), pa in zip(res, adj):
        print("     %-22s vs %-22s solo 1.o=%3d solo 2.o=%3d  p=%.2g  p Holm=%.2g | Wilcoxon por celda p=%.2g" % (a[:22], b_[:22], x, y, p, pa, pw))
#%% Criterio 2: compila (600 respuestas de codigo)
informe(T, "c2_compila", "CRITERIO 2 - compila en CODESYS (estricto)")
#%% Criterio 1: pasa el harness (600 respuestas)
informe(H, "c1_pasa", "CRITERIO 1 - pasa el harness (estricto)")
#%% Categorias de fallo del criterio 1
print("\n===== Categorias (criterio 1) =====")
for m in MODELOS:
    c = collections.Counter(r["c1_categoria"] for r in H if r["modelo"] == m)
    print("  %-26s %s" % (m, "  ".join("%s=%d" % (k, c.get(k, 0)) for k in ("PASA", "FALLA_LOGICA", "INTERFAZ_NO_CONFORME", "NO_COMPILA"))))
#%% Tabla por tarea: aciertos de 3 (zero / few) por modelo
orden = sorted({r["tarea"] for r in H}, key=lambda x: ("BIAC".index(x[0]), int(x[1:])))
idx = {(r["modelo"], r["tarea"], r["estrategia"]): 0 for r in H}
for r in H: idx[(r["modelo"], r["tarea"], r["estrategia"])] += r["c1_pasa"]
print("\n===== Criterio 1 por tarea: aciertos de 3 (zero/few) =====")
print("  tarea  " + "".join("%-14s" % m[:12] for m in MODELOS) + " total/24")
filas_tarea = []
for t in orden:
    tot = sum(idx[(m, t, e)] for m in MODELOS for e in ESTR)
    print("  %-6s " % t + "".join("%-14s" % ("%d / %d" % (idx[(m, t, "zero_shot")], idx[(m, t, "few_shot")])) for m in MODELOS) + " %2d" % tot)
    filas_tarea.append([t] + [idx[(m, t, e)] for m in MODELOS for e in ESTR] + [tot])
with open("data/results/c1_por_tarea_definitivo.csv", "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.writer(fh); w.writerow(["tarea"] + ["%s|%s" % (m, e) for m in MODELOS for e in ESTR] + ["total_de_24"]); w.writerows(filas_tarea)
#%% Misma logica pedida en lenguaje natural (B3, B2) y en Ladder (C7, C8)
print("\n===== Lenguaje natural vs Ladder: aciertos de 6 por modelo =====")
for ln, ld in (("B3", "C7"), ("B2", "C8")):
    print("  %s (LN) vs %s (LD): " % (ln, ld) + "  ".join("%s %d/%d" % (m[:6], sum(idx[(m, ln, e)] for e in ESTR), sum(idx[(m, ld, e)] for e in ESTR)) for m in MODELOS))
#%% Casos senalados (INC-33 e INC-34)
print("\n===== Casos senalados =====")
print("  variable `dt` (INC-33):", dict(collections.Counter((r["tarea"], r["modelo"][:6]) for r in T if r["caso_dt"])))
print("  `END_STRUCT;` (INC-34):", dict(collections.Counter((r["tarea"], r["modelo"][:6]) for r in T if r["caso_end_struct"])))
#%% Sensibilidad S1: sin la tarea A1
sinA1 = {t for t in TAREAS if t != "A1"}
informe(T, "c2_compila", "S1 - CRITERIO 2 sin A1", sinA1)
informe(H, "c1_pasa", "S1 - CRITERIO 1 sin A1", sinA1)
#%% Sensibilidad S2: END_STRUCT; normalizado (requiere los CSV sens_*.csv)
p_c, p_s = RC + "sens_endstruct_compilacion.csv", RC + "sens_endstruct_simulacion.csv"
if os.path.exists(p_c) and os.path.exists(p_s):
    cc = {(r["modelo"], r["tarea"], r["estrategia"], clave_ejec(r["ejecucion"])): r for r in leer(p_c)}
    ss = {}
    for r in leer(p_s):
        mo, es, ej = r["id"].split("|"); ss[(mo, r["tarea"], es, ej)] = r
    T2 = []
    for r in T:
        k = (r["modelo"], r["tarea"], r["estrategia"], r["ejec"]); q = dict(r)
        if r["caso_end_struct"] and k in cc:
            q["c2_compila"] = int(cc[k]["compila"] == "1")
            if k in ss: q["c1_pasa"] = int(ss[k]["veredicto"] == "1"); q["c1_categoria"] = categoria(cc[k], ss[k])
            print("  S2 %s %s %s %s: compila %d -> %d | pasa %s -> %s" % (k + (r["c2_compila"], q["c2_compila"], r["c1_pasa"], q["c1_pasa"])))
        T2.append(q)
    informe(T2, "c2_compila", "S2 - CRITERIO 2 con END_STRUCT; normalizado")
    informe([r for r in T2 if r["con_harness"]], "c1_pasa", "S2 - CRITERIO 1 con END_STRUCT; normalizado")
else:
    print("\n[S2 pendiente] faltan %s y %s" % (p_c, p_s))
