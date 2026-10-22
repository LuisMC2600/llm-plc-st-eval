# -*- coding: utf-8 -*-
"""Analiza la rúbrica de 5 criterios sobre las 600 respuestas de código.

Evaluación oficial: evaluador LLM DeepSeek deepseek-v4-pro (INC-35, decisión del 2026-10-09).
Segundo evaluador, solo para confiabilidad: Claude.
Lee las celdas de las dos fichas, las descodifica con _SELLADO_asignacion_rubrica.csv y calcula:
  - medias (DE) de cada criterio y del total por modelo, por modelo × estrategia y por nivel;
  - efecto de la estrategia few-shot frente a zero-shot por modelo: Wilcoxon de rangos con signo,
    pareado por tarea × ejecución, con corrección de Holm dentro de cada criterio;
  - concordancia entre evaluadores: kappa ponderado cuadrático, acuerdo exacto y ±1.
Este script NO califica: solo cuenta.
Uso (desde llm-plc-st-eval):
  python evaluacion_rubrica/analizar_rubrica.py [ficha_oficial.xlsx] [ficha_segundo.xlsx] [carpeta_salida]
"""
import csv, os, sys, statistics as st
from openpyxl import load_workbook
from scipy.stats import wilcoxon

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
F1 = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RAIZ, "evaluacion_llm", "OFICIAL", "Ficha_Oficial_Rubrica_DeepSeek.xlsx")
F2 = sys.argv[2] if len(sys.argv) > 2 else os.path.join(RAIZ, "evaluacion_llm", "CONFIABILIDAD", "Ficha_Confiabilidad_Rubrica_Claude.xlsx")
SAL = sys.argv[3] if len(sys.argv) > 3 else os.path.join(RAIZ, "data", "results")
MODELOS = ["gemini-3.1-pro-preview", "claude-sonnet-4-6", "gpt-4o-2024-08-06", "qwen2.5-coder_14b"]
CRIT = ["funcional", "iec", "coherencia", "claridad", "mantenibilidad"]
ASIG = {r["codigo"]: r for r in csv.DictReader(open(os.path.join(AQUI, "_SELLADO_asignacion_rubrica.csv"), encoding="utf-8-sig"))}


def leer(ruta):
    wb = load_workbook(ruta, data_only=True); d = {}
    for ws in wb.worksheets[2:]:
        f = 6
        while ws.cell(f, 1).value:
            cod = ws.cell(f, 1).value
            vals = [ws.cell(f, c).value for c in range(3, 8)]
            if any(not isinstance(v, (int, float)) for v in vals):
                sys.exit(f"Ficha incompleta: {ruta} {cod}")
            d[cod] = dict(zip(CRIT, map(int, vals)))
            d[cod]["total"] = sum(d[cod][k] for k in CRIT)
            d[cod]["resultado_codesys"] = ws.cell(f, 2).value; d[cod]["codigo"] = cod
            f += 1
    return d


def kw(a, b, k=4):
    n = len(a); w = lambda i, j: 1 - ((i - j) / (k - 1)) ** 2
    pa = [sum(1 for x in a if x == i) / n for i in range(k)]; pb = [sum(1 for x in b if x == i) / n for i in range(k)]
    po = sum(w(x, y) for x, y in zip(a, b)) / n
    pe = sum(w(i, j) * pa[i] * pb[j] for i in range(k) for j in range(k))
    return (po - pe) / (1 - pe) if pe < 1 else float("nan")


def holm(ps):
    orden = sorted(range(len(ps)), key=lambda i: ps[i]); adj = [0.0] * len(ps); m = len(ps); prev = 0
    for r, i in enumerate(orden):
        prev = max(prev, min(1.0, (m - r) * ps[i])); adj[i] = prev
    return adj


O = leer(F1); S = leer(F2) if os.path.exists(F2) else {}
assert set(O) == set(ASIG), "los códigos de la ficha oficial no coinciden con la asignación sellada"
for c in O: O[c].update({k: ASIG[c][k] for k in ("tarea", "modelo", "estrategia", "ejec")}); O[c]["nivel"] = c[0]
R = list(O.values())
ms = lambda xs: "%.2f (%.2f)" % (st.mean(xs), st.pstdev(xs))

print("===== RÚBRICA OFICIAL (evaluador LLM DeepSeek deepseek-v4-pro): %d respuestas =====" % len(R))
print("Media (DE) por criterio, escala 0–3; total 0–15")
print("%-24s %-13s " % ("modelo", "estrategia") + " ".join("%-12s" % k[:12] for k in CRIT + ["total"]))
for m in MODELOS + ["TODOS"]:
    for e in ("ambas", "zero_shot", "few_shot"):
        X = [r for r in R if m in ("TODOS", r["modelo"]) and e in ("ambas", r["estrategia"])]
        print("%-24s %-13s " % (m[:24], e) + " ".join("%-12s" % ms([r[k] for r in X]) for k in CRIT + ["total"]))
print("\nPor nivel (B básico, I intermedio, A avanzado, C comparativa):")
for nv in "BIAC":
    X = [r for r in R if r["nivel"] == nv]
    print("  %s (n=%d) " % (nv, len(X)) + " ".join("%s %s" % (k[:6], ms([r[k] for r in X])) for k in CRIT + ["total"]))

print("\n===== FEW-SHOT vs ZERO-SHOT por modelo (Wilcoxon pareado por tarea × ejecución; Holm por criterio) =====")
for k in CRIT + ["total"]:
    filas = []
    for m in MODELOS:
        z = {(r["tarea"], r["ejec"]): r[k] for r in R if r["modelo"] == m and r["estrategia"] == "zero_shot"}
        f = {(r["tarea"], r["ejec"]): r[k] for r in R if r["modelo"] == m and r["estrategia"] == "few_shot"}
        par = [(z[x], f[x]) for x in z if x in f]
        d = [b - a for a, b in par]
        p = wilcoxon(d).pvalue if any(d) else 1.0
        filas.append((m, len(par), st.mean(d), p))
    adj = holm([x[3] for x in filas])
    for (m, n, dm, p), pa in zip(filas, adj):
        print("  %-14s %-24s n=%2d  dif. media few−zero %+.2f  p=%.4f  p_Holm=%.4f%s" % (k, m, n, dm, p, pa, "  *" if pa < 0.05 else ""))

if S:
    print("\n===== CONCORDANCIA ENTRE EVALUADORES (oficial DeepSeek vs segundo Claude), %d respuestas =====" % len(set(O) & set(S)))
    com = sorted(set(O) & set(S))
    for k in CRIT:
        fij = lambda c: (str(O[c]["resultado_codesys"]).startswith("No compila") or
                         (k == "funcional" and "Pasa" in str(O[c]["resultado_codesys"]) and "Falla" not in str(O[c]["resultado_codesys"])))
        cs = [c for c in com if not (k in ("funcional", "iec") and fij(c))]
        a = [O[c][k] for c in cs]; b = [S[c][k] for c in cs]
        print("  %-15s n=%3d  exacto %5.1f %%  ±1 %5.1f %%  kappa ponderado %.2f  dif. media oficial−segundo %+.2f%s" % (
            k, len(cs), 100 * sum(x == y for x, y in zip(a, b)) / len(cs), 100 * sum(abs(x - y) <= 1 for x, y in zip(a, b)) / len(cs),
            kw(a, b), st.mean(a) - st.mean(b), "  (solo celdas no fijadas por CODESYS)" if k in ("funcional", "iec") else ""))
    print("  Referencia: < 0,40 pobre; 0,41–0,60 moderado; 0,61–0,80 sustancial; > 0,80 casi perfecto (Landis y Koch, 1977).")

os.makedirs(SAL, exist_ok=True)
with open(os.path.join(SAL, "rubrica_definitivo.csv"), "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.writer(fh)
    w.writerow(["codigo", "tarea", "nivel", "modelo", "estrategia", "ejec", "resultado_codesys"] + CRIT + ["total"] +
               ["seg_" + k for k in CRIT] + ["evaluador_oficial"])
    for r in sorted(R, key=lambda r: (r["tarea"], r["modelo"], r["estrategia"], r["ejec"])):
        s = S.get(r["codigo"], {})
        w.writerow([r["codigo"], r["tarea"], r["nivel"], r["modelo"], r["estrategia"], r["ejec"], r["resultado_codesys"]] +
                   [r[k] for k in CRIT] + [r["total"]] + [s.get(k, "") for k in CRIT] + ["deepseek-v4-pro"])
print("\nGuardado: %s" % os.path.join(SAL, "rubrica_definitivo.csv"))
