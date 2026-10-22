# -*- coding: utf-8 -*-
"""Contraste de la hipótesis de trabajo con los datos definitivos (Agente B, 2026-10-12).

CÁLCULO NUEVO (no publicado en el documento maestro v0.2). Solo lee los insumos; no escribe en ellos.

Entradas (solo lectura):
  data/results/tabla_definitivo.csv   600 respuestas de código: c1_pasa, c2_compila, nivel, modelo...
  data/results/rubrica_definitivo.csv 600 puntuaciones oficiales (DeepSeek) de la rúbrica 0-15

Bloques:
  0. Verificación: reproduce las cifras ya publicadas (Tablas 4.3, 4.4, 4.5, 4.6, 4.10, texto 4.8,
     sensibilidad S1). Si alguna no coincide, el script se detiene.
  1. H-a (complejidad): Básico < Intermedio < Avanzado, Complementarias excluidas.
     a) descriptiva por modelo y nivel (c1, c2, total de rúbrica);
     b) prueba de tendencia de Cochran-Armitage (puntuaciones 0, 1, 2) sobre respuestas;
     c) regresión logística (GEE, correlación intercambiable, clúster = tarea, varianza robusta
        con corrección de sesgo de Mancl-DeRouen) de c1/c2 sobre el nivel ordinal;
        regresión lineal GEE equivalente para el total de rúbrica;
     d) prueba de permutación de Jonckheere-Terpstra con la TAREA como unidad (22 tareas) y tau-b de Kendall;
     e) sensibilidad sin A1 (INC-33).
  2. H-b (few-shot): global y por modelo, c1, c2 y total; Holm sobre los 4 modelos.
  3. H-c (especialización): Qwen 2.5 Coder frente a cada generalista (c1, c2, total).

Uso (desde la raíz del repositorio): python analisis/contraste_hipotesis.py > analisis/contraste_hipotesis_salida.txt
"""
import sys, os, math, itertools, warnings
import numpy as np
import pandas as pd
from scipy.stats import binomtest, wilcoxon, norm, kendalltau
import statsmodels.api as sm
from statsmodels.genmod.generalized_estimating_equations import GEE
from statsmodels.genmod.cov_struct import Exchangeable

warnings.filterwarnings("ignore")
# Versión publicada: por defecto lee desde la raíz del repositorio (data/results/);
# en la copia de trabajo original los insumos estaban en otra carpeta. El cálculo no cambia.
RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = pd.read_csv(os.path.join(RAIZ, "data/results/tabla_definitivo.csv"), encoding="utf-8-sig")
R = pd.read_csv(os.path.join(RAIZ, "data/results/rubrica_definitivo.csv"), encoding="utf-8-sig")

MODELOS = ["gemini-3.1-pro-preview", "claude-sonnet-4-6", "gpt-4o-2024-08-06", "qwen2.5-coder_14b"]
CORTO = {"gemini-3.1-pro-preview": "Gemini", "claude-sonnet-4-6": "Claude",
         "gpt-4o-2024-08-06": "GPT-4o", "qwen2.5-coder_14b": "Qwen"}
NIVELES = ["Basico", "Intermedio", "Avanzado"]
ORD = {"Basico": 0, "Intermedio": 1, "Avanzado": 2}
R["nivel_l"] = R["nivel"].map({"B": "Basico", "I": "Intermedio", "A": "Avanzado", "C": "Complementaria"})

# Unión de ambas tablas por respuesta (modelo, tarea, estrategia, ejecución)
K = ["modelo", "tarea", "estrategia", "ejec"]
D = T.merge(R[K + ["funcional", "iec", "coherencia", "claridad", "mantenibilidad", "total"]], on=K, how="inner")
assert len(D) == 600, "la unión de tabla y rúbrica no tiene 600 filas"


def pct(k, n):
    return "%d/%d = %.1f %%" % (k, n, 100.0 * k / n)


def holm(ps):
    orden = sorted(range(len(ps)), key=lambda i: ps[i]); adj = [0.0] * len(ps); ant = 0.0
    for j, i in enumerate(orden):
        ant = max(ant, min(1.0, (len(ps) - j) * ps[i])); adj[i] = ant
    return adj


def mcnemar(a, b):
    """a, b: vectores 0/1 pareados. Devuelve (solo_a, solo_b, p exacta bilateral)."""
    sa = int(((a == 1) & (b == 0)).sum()); sb = int(((a == 0) & (b == 1)).sum())
    return sa, sb, (binomtest(sa, sa + sb, 0.5).pvalue if sa + sb else 1.0)


# =====================================================================================
print("=" * 90)
print("0. VERIFICACIÓN CONTRA CIFRAS PUBLICADAS (documento maestro v0.2 y analisis_salidas)")
print("=" * 90)
chk = []
def ver(nombre, obtenido, esperado):
    ok = obtenido == esperado
    chk.append(ok)
    print("  [%s] %-58s obtenido=%s  publicado=%s" % ("OK" if ok else "XX", nombre, obtenido, esperado))

ver("Tabla 4.3 c1 global", int(T.c1_pasa.sum()), 351)
ver("Tabla 4.3 c2 global", int(T.c2_compila.sum()), 518)
for m, c1, c2 in zip(MODELOS, [141, 114, 54, 42], [143, 136, 119, 120]):
    ver("Tabla 4.3 c1 " + CORTO[m], int(T[T.modelo == m].c1_pasa.sum()), c1)
    ver("Tabla 4.3 c2 " + CORTO[m], int(T[T.modelo == m].c2_compila.sum()), c2)
for nv, c1, c2, n in [("Basico", 139, 189, 192), ("Intermedio", 104, 178, 192),
                      ("Avanzado", 52, 80, 144), ("Complementaria", 56, 71, 72)]:
    s = T[T.nivel == nv]
    ver("Tabla 4.5 " + nv + " c1 (k, n)", (int(s.c1_pasa.sum()), len(s)), (c1, n))
    ver("Tabla 4.5 " + nv + " c2 (k, n)", (int(s.c2_compila.sum()), len(s)), (c2, n))
pub44 = {"gemini-3.1-pro-preview": (70, 71, 2, 3, 1.000), "claude-sonnet-4-6": (56, 58, 10, 12, 0.832),
         "gpt-4o-2024-08-06": (20, 34, 2, 16, 0.001), "qwen2.5-coder_14b": (21, 21, 10, 10, 1.000)}
for m, (z, f, sz, sf, p) in pub44.items():
    s = T[T.modelo == m]
    Z = s[s.estrategia == "zero_shot"].set_index(["tarea", "ejec"]).c1_pasa
    F = s[s.estrategia == "few_shot"].set_index(["tarea", "ejec"]).c1_pasa.reindex(Z.index)
    a, b, pp = mcnemar(Z.values, F.values)
    ver("Tabla 4.4 " + CORTO[m] + " (zero, few, solo_z, solo_f, p)", (int(Z.sum()), int(F.sum()), a, b, round(pp, 3)), (z, f, sz, sf, p))
cat = T.groupby(["modelo", "c1_categoria"]).size().unstack(fill_value=0)
for m, fl, inc, nc in zip(MODELOS, [2, 22, 43, 72], [0, 0, 22, 6], [7, 14, 31, 30]):
    ver("Tabla 4.6 " + CORTO[m], (int(cat.loc[m, "FALLA_LOGICA"]), int(cat.loc[m].get("INTERFAZ_NO_CONFORME", 0)),
                                  int(cat.loc[m, "NO_COMPILA"])), (fl, inc, nc))
for m, tot in zip(MODELOS, [12.71, 11.84, 7.99, 6.94]):
    ver("Tabla 4.10 total " + CORTO[m], round(R[R.modelo == m].total.mean(), 2), tot)
ver("Tabla 4.10 total global", round(R.total.mean(), 2), 9.87)
for nv, tot in zip("BIAC", [10.78, 9.48, 8.26, 11.67]):
    ver("Texto 4.8 total nivel " + nv, round(R[R.nivel == nv].total.mean(), 2), tot)
sinA1 = T[(T.tarea != "A1") & (T.nivel == "Avanzado")]
ver("S1 sin A1, Avanzado c1 (k, n)", (int(sinA1.c1_pasa.sum()), len(sinA1)), (49, 120))
ver("S1 sin A1, Avanzado c2 (k, n)", (int(sinA1.c2_compila.sum()), len(sinA1)), (77, 120))
# coherencia interna entre las dos tablas (regla de la sección 3.7.3)
ver("rúbrica funcional = 3  <=>  c1_pasa = 1", int(((D.funcional == 3) == (D.c1_pasa == 1)).sum()), 600)
ver("rúbrica IEC = 0        <=>  c2_compila = 0", int(((D.iec == 0) == (D.c2_compila == 0)).sum()), 600)
if not all(chk):
    sys.exit("\nVERIFICACIÓN FALLIDA: no se continúa.")
print("\n  VERIFICACIÓN OK: %d/%d comprobaciones coinciden con lo publicado.\n" % (sum(chk), len(chk)))


# =====================================================================================
def cochran_armitage(k, n, s=(0, 1, 2)):
    """Prueba de tendencia de Cochran-Armitage (bilateral, aproximación normal, sin corrección N/(N-1))."""
    k, n, s = map(np.asarray, (k, n, s)); N = n.sum(); pbar = k.sum() / N
    Tst = (s * (k - n * pbar)).sum()
    var = pbar * (1 - pbar) * ((n * s ** 2).sum() - (n * s).sum() ** 2 / N)
    z = Tst / math.sqrt(var) if var > 0 else float("nan")
    return z, 2 * norm.sf(abs(z))


def gee(datos, y, formula_x, familia):
    X = pd.get_dummies(datos[formula_x], drop_first=True, dtype=float)
    X = sm.add_constant(X)
    mod = GEE(datos[y].astype(float), X, groups=datos["tarea"], family=familia, cov_struct=Exchangeable())
    try:
        res = mod.fit(cov_type="bias_reduced")
    except Exception:
        res = mod.fit(cov_type="robust")
    b = res.params["nivel_ord"]; se = res.bse["nivel_ord"]; p = res.pvalues["nivel_ord"]
    return b, se, p


def jt_perm(valores, grupos, nperm=200000, semilla=20261012):
    """Jonckheere-Terpstra para tendencia DECRECIENTE con grupos ordenados 0<1<2.
    Estadístico: pares (x en nivel menor, y en nivel mayor) con x > y, más 0.5 por empate.
    p unilateral por permutación de las etiquetas de nivel entre tareas."""
    v = np.asarray(valores, float); g = np.asarray(grupos, int)
    def est(gr):
        tot = 0.0
        for i, j in itertools.combinations(sorted(set(gr)), 2):
            a = v[gr == i][:, None]; b = v[gr == j][None, :]
            tot += (a > b).sum() + 0.5 * (a == b).sum()
        return tot
    obs = est(g)
    rng = np.random.default_rng(semilla)
    # versión vectorizada: matriz de comparaciones entre tareas
    gt = (v[:, None] > v[None, :]).astype(float) + 0.5 * (v[:, None] == v[None, :])
    cnt = 0
    for _ in range(nperm // 1000):
        P = rng.permuted(np.tile(g, (1000, 1)), axis=1)                 # 1000 x ntareas
        menor = (P[:, :, None] < P[:, None, :]).astype(float)          # pares (i en nivel menor, j en nivel mayor)
        s = (menor * gt[None, :, :]).sum(axis=(1, 2))
        cnt += (s >= obs - 1e-9).sum()
    return obs, (cnt + 1) / (nperm + 1)


print("=" * 90)
print("1. H-a  COMPLEJIDAD (Básico < Intermedio < Avanzado; Complementarias excluidas)")
print("=" * 90)
G = D[D.nivel.isin(NIVELES)].copy(); G["nivel_ord"] = G.nivel.map(ORD)
print("\n1a. Descriptiva por modelo y nivel")
print("  %-8s %-26s %-26s %-26s" % ("", "Básico", "Intermedio", "Avanzado"))
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2")):
    for m in MODELOS + ["GLOBAL"]:
        s = G if m == "GLOBAL" else G[G.modelo == m]
        cel = [pct(int(s[s.nivel == nv][var].sum()), int((s.nivel == nv).sum())) for nv in NIVELES]
        print("  %-3s %-6s %-26s %-26s %-26s" % (nom, CORTO.get(m, m), *cel))
for m in MODELOS + ["GLOBAL"]:
    s = G if m == "GLOBAL" else G[G.modelo == m]
    cel = ["%.2f" % s[s.nivel == nv].total.mean() for nv in NIVELES]
    print("  tot %-6s %-26s %-26s %-26s" % (CORTO.get(m, m), *cel))
print("  Complementarias (C3, C7, C8), solo referencia: c1 %s; c2 %s; total %.2f" % (
    pct(int(D[D.nivel == "Complementaria"].c1_pasa.sum()), 72), pct(int(D[D.nivel == "Complementaria"].c2_compila.sum()), 72),
    D[D.nivel == "Complementaria"].total.mean()))

print("\n1b. Cochran-Armitage (respuesta como unidad; supone independencia: optimista)")
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2")):
    for m in MODELOS + ["GLOBAL"]:
        s = G if m == "GLOBAL" else G[G.modelo == m]
        k = [int(s[s.nivel == nv][var].sum()) for nv in NIVELES]; n = [int((s.nivel == nv).sum()) for nv in NIVELES]
        z, p = cochran_armitage(k, n)
        print("  %-3s %-7s Z = %6.2f  p = %.2g" % (nom, CORTO.get(m, m), z, p))

print("\n1c. GEE (clúster = tarea, 22 clústeres; varianza robusta con corrección de sesgo)")
print("    Pendiente por escalón de nivel; para c1/c2 se informa OR = exp(b) con IC 95 %")
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2")):
    b, se, p = gee(G, var, ["nivel_ord", "modelo", "estrategia"], sm.families.Binomial())
    print("  %-3s %-7s OR = %.2f [%.2f; %.2f]  p = %.2g   (ajustado por modelo y estrategia)" % (
        nom, "GLOBAL", math.exp(b), math.exp(b - 1.96 * se), math.exp(b + 1.96 * se), p))
    for m in MODELOS:
        s = G[G.modelo == m]
        try:
            b, se, p = gee(s, var, ["nivel_ord", "estrategia"], sm.families.Binomial())
            print("  %-3s %-7s OR = %.2f [%.2f; %.2f]  p = %.2g" % (
                nom, CORTO[m], math.exp(b), math.exp(b - 1.96 * se), math.exp(b + 1.96 * se), p))
        except Exception as e:
            print("  %-3s %-7s no estimable (%s)" % (nom, CORTO[m], type(e).__name__))
b, se, p = gee(G, "total", ["nivel_ord", "modelo", "estrategia"], sm.families.Gaussian())
print("  tot GLOBAL  pendiente = %+.2f puntos/nivel [%+.2f; %+.2f]  p = %.2g   (ajustado por modelo y estrategia)" % (
    b, b - 1.96 * se, b + 1.96 * se, p))
for m in MODELOS:
    b, se, p = gee(G[G.modelo == m], "total", ["nivel_ord", "estrategia"], sm.families.Gaussian())
    print("  tot %-7s pendiente = %+.2f puntos/nivel [%+.2f; %+.2f]  p = %.2g" % (CORTO[m], b, b - 1.96 * se, b + 1.96 * se, p))

print("\n1d. Tarea como unidad (22 tareas: 8 B, 8 I, 6 A). Jonckheere-Terpstra por permutación")
print("    (200 000 permutaciones, semilla 20261012, p unilateral para tendencia decreciente) y tau-b de Kendall")
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2"), ("total", "tot")):
    for m in MODELOS + ["GLOBAL"]:
        s = G if m == "GLOBAL" else G[G.modelo == m]
        tt = s.groupby("tarea").agg(v=(var, "mean"), g=("nivel_ord", "first"))
        jt, pjt = jt_perm(tt.v.values, tt.g.values)
        tau, ptau = kendalltau(tt.g.values, tt.v.values)
        print("  %-3s %-7s JT = %6.1f  p_perm = %.4f | tau-b = %+.2f  p = %.2g" % (nom, CORTO.get(m, m), jt, pjt, tau, ptau))
tt = G.groupby("tarea").agg(c1=("c1_pasa", "sum"), n=("c1_pasa", "size"), nivel=("nivel", "first"))
print("  Aciertos c1 por tarea (de 24):")
for nv in NIVELES:
    x = tt[tt.nivel == nv]
    print("    %-10s %s | mín %d, máx %d" % (nv, " ".join("%s=%d" % (t, c) for t, c in x.c1.items()), x.c1.min(), x.c1.max()))

print("\n1d-bis. ¿Desciende también la parte de la rúbrica que NO se fija por CODESYS?")
print("    (coherencia + claridad + mantenibilidad, 0-9; funcional e IEC se derivan de c1/c2 por regla, sección 3.7.3)")
G["sub345"] = G.coherencia + G.claridad + G.mantenibilidad
for m in MODELOS + ["GLOBAL"]:
    s = G if m == "GLOBAL" else G[G.modelo == m]
    med = [s[s.nivel == nv].sub345.mean() for nv in NIVELES]
    crit = " | ".join("%s %s" % (k[:5], "/".join("%.2f" % s[s.nivel == nv][k].mean() for nv in NIVELES))
                      for k in ("coherencia", "claridad", "mantenibilidad"))
    tt = s.groupby("tarea").agg(v=("sub345", "mean"), g=("nivel_ord", "first"))
    jt, pjt = jt_perm(tt.v.values, tt.g.values, nperm=100000)
    print("  %-7s sub 3-5: %.2f / %.2f / %.2f  JT p_perm = %.4f | %s" % (CORTO.get(m, m), *med, pjt, crit))

print("\n1e. Sensibilidad sin A1 (INC-33)")
S = G[G.tarea != "A1"]
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2")):
    for m in MODELOS + ["GLOBAL"]:
        s = S if m == "GLOBAL" else S[S.modelo == m]
        k = [int(s[s.nivel == nv][var].sum()) for nv in NIVELES]; n = [int((s.nivel == nv).sum()) for nv in NIVELES]
        z, p = cochran_armitage(k, n)
        tt = s.groupby("tarea").agg(v=(var, "mean"), g=("nivel_ord", "first"))
        jt, pjt = jt_perm(tt.v.values, tt.g.values, nperm=100000)
        print("  %-3s %-7s %s | %s | %s   CA p = %.2g | JT p_perm = %.4f" % (
            nom, CORTO.get(m, m), *[pct(a, b) for a, b in zip(k, n)], p, pjt))


# =====================================================================================
print("\n" + "=" * 90)
print("2. H-b  FEW-SHOT FRENTE A ZERO-SHOT")
print("=" * 90)
def pares(s, var):
    Z = s[s.estrategia == "zero_shot"].set_index(["modelo", "tarea", "ejec"])[var]
    F = s[s.estrategia == "few_shot"].set_index(["modelo", "tarea", "ejec"])[var].reindex(Z.index)
    return Z, F
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2")):
    print("\n  %s  (McNemar exacto pareado por modelo x tarea x ejecución; Wilcoxon por celda modelo x tarea)" % nom)
    filas = []
    for m in MODELOS + ["GLOBAL"]:
        s = D if m == "GLOBAL" else D[D.modelo == m]
        Z, F = pares(s, var)
        a, b, p = mcnemar(Z.values, F.values)
        dz = (F.groupby(level=[0, 1]).sum() - Z.groupby(level=[0, 1]).sum()).values
        pw = wilcoxon(dz).pvalue if np.any(dz) else 1.0
        filas.append((m, int(Z.sum()), int(F.sum()), len(Z), a, b, p, pw))
    adj = holm([f[6] for f in filas[:4]]) + [float("nan")]
    for (m, z, f, n, a, b, p, pw), pa in zip(filas, adj):
        print("    %-7s zero %-18s few %-18s dif %+5.1f pp | solo zero %2d, solo few %2d  p = %.3g  p_Holm(4) = %s | Wilcoxon p = %.3g" % (
            CORTO.get(m, m), pct(z, n), pct(f, n), 100.0 * (f - z) / n, a, b, p, "—" if math.isnan(pa) else "%.3g" % pa, pw))
print("\n  total de rúbrica (Wilcoxon pareado por tarea x ejecución dentro de modelo; global: 300 pares)")
for m in MODELOS + ["GLOBAL"]:
    s = D if m == "GLOBAL" else D[D.modelo == m]
    Z, F = pares(s, "total")
    d = (F - Z).values
    print("    %-7s zero %.2f  few %.2f  dif %+.2f  Wilcoxon p = %.2g  (pares que mejoran %d, empeoran %d, iguales %d)" % (
        CORTO.get(m, m), Z.mean(), F.mean(), d.mean(), wilcoxon(d).pvalue, (d > 0).sum(), (d < 0).sum(), (d == 0).sum()))
print("\n  Global sin GPT-4o (¿la mejora global depende de un solo modelo?)")
s = D[D.modelo != "gpt-4o-2024-08-06"]
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2")):
    Z, F = pares(s, var); a, b, p = mcnemar(Z.values, F.values)
    print("    %-3s zero %-18s few %-18s solo zero %2d, solo few %2d  p = %.3g" % (nom, pct(int(Z.sum()), len(Z)), pct(int(F.sum()), len(F)), a, b, p))
Z, F = pares(s, "total"); d = (F - Z).values
print("    tot zero %.2f  few %.2f  dif %+.2f  Wilcoxon p = %.3g" % (Z.mean(), F.mean(), d.mean(), wilcoxon(d).pvalue))
print("\n  c1 por nivel y estrategia (todos los modelos; exploratorio)")
for nv in NIVELES + ["Complementaria"]:
    s = D[D.nivel == nv]; Z, F = pares(s, "c1_pasa"); a, b, p = mcnemar(Z.values, F.values)
    print("    %-14s zero %-18s few %-18s solo zero %2d, solo few %2d  p = %.2g" % (nv, pct(int(Z.sum()), len(Z)), pct(int(F.sum()), len(F)), a, b, p))
print("\n  Categorías del criterio 1 por modelo y estrategia (exploratorio: ¿sobre qué actúan los ejemplos?)")
cc = D.groupby(["modelo", "estrategia", "c1_categoria"]).size().unstack(fill_value=0)
for m in MODELOS:
    for e in ("zero_shot", "few_shot"):
        x = cc.loc[(m, e)]
        print("    %-7s %-9s PASA %2d | FALLA_LOGICA %2d | INTERFAZ_NO_CONFORME %2d | NO_COMPILA %2d" % (
            CORTO[m], e, x.get("PASA", 0), x.get("FALLA_LOGICA", 0), x.get("INTERFAZ_NO_CONFORME", 0), x.get("NO_COMPILA", 0)))
print("\n  Tareas con cambio de 3 o más aciertos (de 3+3) entre estrategias, por modelo (c1)")
pt = D.groupby(["modelo", "tarea", "estrategia"]).c1_pasa.sum().unstack()
pt["dif"] = pt["few_shot"] - pt["zero_shot"]
for m in MODELOS:
    x = pt.loc[m]; x = x[x.dif.abs() >= 3]
    print("    %-7s %s" % (CORTO[m], ", ".join("%s %d->%d" % (t, r.zero_shot, r.few_shot) for t, r in x.iterrows()) or "ninguna"))


# =====================================================================================
print("\n" + "=" * 90)
print("3. H-c  ESPECIALIZACIÓN (Qwen 2.5 Coder 14B, único modelo especializado en código, frente a cada generalista)")
print("=" * 90)
q = "qwen2.5-coder_14b"; gen = ["gemini-3.1-pro-preview", "claude-sonnet-4-6", "gpt-4o-2024-08-06"]
idx = D.set_index(["modelo", "tarea", "estrategia", "ejec"]).sort_index()
for var, nom in (("c1_pasa", "c1"), ("c2_compila", "c2")):
    res = []
    for g in gen:
        A = idx.loc[q][var]; B = idx.loc[g][var].reindex(A.index)
        a, b, p = mcnemar(A.values, B.values); res.append((g, int(A.sum()), int(B.sum()), a, b, p))
    adj = holm([r[5] for r in res])
    for (g, ka, kb, a, b, p), pa in zip(res, adj):
        print("  %-3s Qwen %-17s vs %-7s %-17s solo Qwen %2d, solo generalista %3d  p = %.2g  p_Holm(3) = %.2g" % (
            nom, pct(ka, 150), CORTO[g], pct(kb, 150), a, b, p, pa))
res = []
for g in gen:
    A = idx.loc[q]["total"]; B = idx.loc[g]["total"].reindex(A.index); d = (A - B).values
    res.append((g, A.mean(), B.mean(), d.mean(), wilcoxon(d).pvalue))
adj = holm([r[4] for r in res])
for (g, ma, mb, dm, p), pa in zip(res, adj):
    print("  tot Qwen %.2f vs %-7s %.2f  dif %+.2f  Wilcoxon p = %.2g  p_Holm(3) = %.2g" % (ma, CORTO[g], mb, dm, p, pa))
print("\nFin.")
