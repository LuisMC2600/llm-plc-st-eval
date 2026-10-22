# -*- coding: utf-8 -*-
# =============================================================================
# analisis_v03_spyder.py
# Evidencia de los análisis nuevos de la versión 0.3 del documento maestro
# (tesis «LLMs como Asistentes de Programación PLC en la Academia», FIE-UTP).
#
# Reproduce e imprime en consola:
#   (a) Sensibilidad S2 ampliada (9 copias normalizadas por dialecto)
#   (b) Taxonomía final de los 249 fallos por modelo, nivel y estrategia
#   (c) Concordancia DeepSeek-Claude en las 51 clasificaciones por juicio
#   (d) Contraste de la hipótesis: tendencia por nivel y efecto few-shot
#       (la regresión GEE, que requiere statsmodels, va en una celda opcional)
#   (e) Consistencia entre las tres ejecuciones de cada celda (sección 4.4.5)
#
# USO EN SPYDER: abrir el archivo, ajustar BASE en la celda 0 y ejecutar
# celda por celda (Ctrl+Enter) o completo (F5). La celda 0 debe correrse
# primero: define las rutas, carga los datos y las funciones comunes.
# Requisitos: pandas, numpy, scipy. Opcional: statsmodels (celda 7).
# Solo lee archivos; no escribe nada en el repositorio.
# Nota (INC-09): no se usa __doc__ ni __file__, que fallan en modo celda.
# =============================================================================

# %% 0. Configuración, rutas y carga de datos
import os
import math
import itertools
import warnings
import numpy as np
import pandas as pd
from scipy.stats import norm, wilcoxon, kendalltau
try:
    from scipy.stats import binomtest

    def p_binom(k, n):
        return binomtest(k, n, 0.5).pvalue
except ImportError:  # SciPy < 1.7
    from scipy.stats import binom_test

    def p_binom(k, n):
        return binom_test(k, n, 0.5)

warnings.filterwarnings("ignore")
pd.set_option("display.width", 160)
pd.set_option("display.max_columns", 20)

# ---- Ruta de la carpeta raíz del repositorio clonado (AJUSTAR) -------------
# Versión publicada: en la copia de trabajo original BASE apuntaba a la carpeta
# del trabajo de grado y la taxonomía se leía de un borrador; aquí todo se lee
# desde el propio repositorio. El cálculo no cambia.
BASE = r"C:\ruta\a\llm-plc-st-eval"
# Número de permutaciones de Jonckheere-Terpstra (200 000 en la tesis; con
# 20 000 la celda 6 corre unas diez veces más rápido, con p casi iguales).
NPERM = 200000
SEMILLA = 20261012

REPO = BASE
CARPETA_C = os.path.join(REPO, "analisis", "taxonomia_cwe")


def buscar(nombre, *carpetas):
    """Devuelve la primera ruta existente de `nombre` en las carpetas dadas;
    si no aparece, la busca bajo BASE (una sola vez por archivo)."""
    for c in carpetas:
        r = os.path.join(c, nombre)
        if os.path.isfile(r):
            return r
    for raiz, _, archivos in os.walk(BASE):
        if nombre in archivos:
            return os.path.join(raiz, nombre)
    raise FileNotFoundError("No se encontró %s bajo %s" % (nombre, BASE))


RUTA = {
    "tabla": buscar("tabla_definitivo.csv", os.path.join(REPO, "data", "results")),
    "rubrica": buscar("rubrica_definitivo.csv", os.path.join(REPO, "data", "results")),
    "sens_endstruct": buscar("sens_endstruct_simulacion.csv", os.path.join(REPO, "data", "results_codesys")),
    "sens_dialecto": buscar("sens_dialecto_simulacion.csv", os.path.join(REPO, "data", "results_codesys")),
    "taxonomia": buscar("clasificacion_fallos_cwe.csv", CARPETA_C),
    "concordancia": buscar("concordancia_juicio_deepseek_claude.csv", CARPETA_C,
                           os.path.join(CARPETA_C, "revision_deepseek")),
}
T = pd.read_csv(RUTA["tabla"], encoding="utf-8-sig")
R = pd.read_csv(RUTA["rubrica"], encoding="utf-8-sig")
CWE = pd.read_csv(RUTA["taxonomia"], encoding="utf-8-sig")
CONC = pd.read_csv(RUTA["concordancia"], encoding="utf-8-sig")

MODELOS = ["gemini-3.1-pro-preview", "claude-sonnet-4-6", "gpt-4o-2024-08-06", "qwen2.5-coder_14b"]
CORTO = {"gemini-3.1-pro-preview": "Gemini", "claude-sonnet-4-6": "Claude",
         "gpt-4o-2024-08-06": "GPT-4o", "qwen2.5-coder_14b": "Qwen"}
NIVELES = ["Basico", "Intermedio", "Avanzado"]
ORD = {"Basico": 0, "Intermedio": 1, "Avanzado": 2}
K = ["modelo", "tarea", "estrategia", "ejec"]
D = T.merge(R[K + ["funcional", "iec", "coherencia", "claridad", "mantenibilidad", "total"]], on=K, how="inner")
# Respuestas de los tres niveles de la escala (sin complementarias), usadas en las celdas 5, 6 y 7b
G = D[D.nivel.isin(NIVELES)].copy()
G["nivel_ord"] = G.nivel.map(ORD)

# Categorías de la taxonomía (celdas 2 y 3)
ORDEN_CAT = ["TEMPORIZACION", "CONSTRUCCION", "INTERFAZ", "SECUENCIA", "CONVERSION",
             "INICIALIZACION", "SEGURIDAD", "DIALECTO", "FLANCO", "CALCULO"]
NOMBRE_CAT = {"TEMPORIZACION": "Temporización", "CONSTRUCCION": "Construcción no válida",
              "INTERFAZ": "Interfaz no conforme", "SECUENCIA": "Secuencia y estados",
              "CONVERSION": "Conversión de tipos", "INICIALIZACION": "Inicialización y reinicio",
              "SEGURIDAD": "Paro y enclavamiento", "DIALECTO": "Dependencia del dialecto",
              "FLANCO": "Flanco y conteo", "CALCULO": "Cálculo y rango"}
CWE["Modelo"] = CWE.modelo.map(CORTO)

CHEQUEOS = []  # (descripción, obtenido, esperado) para el resumen de la celda 9


def chequeo(desc, obtenido, esperado):
    ok = obtenido == esperado
    CHEQUEOS.append((desc, ok))
    print("  [%s] %-52s obtenido = %-14s esperado = %s" % ("OK" if ok else "XX", desc, obtenido, esperado))


def pct(k, n):
    return "%d/%d = %.1f %%" % (k, n, 100.0 * k / n) if n else "0/0"


def titulo(t):
    print("\n" + "=" * 92 + "\n" + t + "\n" + "=" * 92)


titulo("0. ARCHIVOS LEÍDOS")
for k, v in RUTA.items():
    print("  %-15s %s" % (k, v))
print("  Filas: tabla %d | rúbrica %d | unión %d | taxonomía %d | concordancia %d"
      % (len(T), len(R), len(D), len(CWE), len(CONC)))
chequeo("respuestas de código (tabla)", len(T), 600)
chequeo("unión tabla-rúbrica", len(D), 600)

# %% 1. (a) Sensibilidad S2 ampliada: 7 END_STRUCT; + 2 R -> RESET (9 copias)
titulo("1. SENSIBILIDAD S2 AMPLIADA (dialecto de CODESYS normalizado en 9 copias)")
casos = []
for clave in ("sens_endstruct", "sens_dialecto"):
    s = pd.read_csv(RUTA[clave])
    for _, r in s.iterrows():
        m, e, x = r["id"].split("|")
        casos.append((m, r["tarea"], e, x, int(r["compila"] == 1), int(r["veredicto"] == 1), clave))
print("  %-24s %-5s %-10s %-7s %-8s %-6s %s" % ("modelo", "tarea", "estrategia", "ejec", "compila", "pasa", "origen"))
for c in casos:
    print("  %-24s %-5s %-10s %-7s %-8d %-6d %s" % (CORTO.get(c[0], c[0]), c[1], c[2], c[3], c[4], c[5], c[6]))
T2 = T.copy()
for m, ta, e, x, comp, pasa, _ in casos:
    k = (T2.modelo == m) & (T2.tarea == ta) & (T2.estrategia == e) & (T2.ejec == x)
    assert k.sum() == 1, "la copia normalizada no corresponde a una sola respuesta"
    T2.loc[k, "c2_compila"] = 1
    T2.loc[k, "c1_pasa"] = pasa
print("\n  Copias normalizadas: %d; compilan: %d; pasan el banco de prueba: %d"
      % (len(casos), sum(c[4] for c in casos), sum(c[5] for c in casos)))
print("  Estricto     : C2 %s | C1 %s" % (pct(int(T.c2_compila.sum()), 600), pct(int(T.c1_pasa.sum()), 600)))
print("  S2 ampliado  : C2 %s | C1 %s" % (pct(int(T2.c2_compila.sum()), 600), pct(int(T2.c1_pasa.sum()), 600)))
print("\n  Por modelo (de 150)    C2 estricto  C2 S2   C1 estricto  C1 S2")
for m in MODELOS:
    a, b = T[T.modelo == m], T2[T2.modelo == m]
    print("  %-22s %8d %8d %10d %8d" % (CORTO[m], a.c2_compila.sum(), b.c2_compila.sum(), a.c1_pasa.sum(), b.c1_pasa.sum()))
print()
chequeo("S2 ampliado: C2 (de 600)", int(T2.c2_compila.sum()), 527)
chequeo("S2 ampliado: C1 (de 600)", int(T2.c1_pasa.sum()), 355)
chequeo("S2 ampliado: copias que pasan", sum(c[5] for c in casos), 4)

# %% 2. (b) Taxonomía final: categoría por modelo, método y entradas CWE
titulo("2. TAXONOMÍA FINAL DE LOS 249 FALLOS (DeepSeek oficial en los 51 casos por juicio)")
tab = pd.crosstab(CWE.categoria_plc, CWE.Modelo).reindex(index=ORDEN_CAT, columns=["Gemini", "Claude", "GPT-4o", "Qwen"]).fillna(0).astype(int)
tab["Total"] = tab.sum(axis=1)
tab.loc["TOTAL"] = tab.sum()
tab["%"] = ["%.1f" % v for v in 100.0 * tab.Total / tab.loc["TOTAL", "Total"]]
tab.index = [NOMBRE_CAT.get(c, "Total") for c in tab.index]
print(tab.to_string())
print("\n  Método de clasificación:")
for met, n in CWE.metodo.value_counts().items():
    print("    %-14s %s" % (met, pct(int(n), len(CWE))))
print("\n  Tipo de fallo (criterio 1):", CWE.c1_categoria.value_counts().to_dict())
print("\n  Entradas CWE asignadas:")
print(CWE.groupby(["cwe_id", "cwe_nombre"]).size().sort_values(ascending=False).to_string())
print()
esperado = [75, 50, 28, 22, 18, 17, 15, 14, 9, 1]
chequeo("totales por categoría", [int(tab.loc[NOMBRE_CAT[c], "Total"]) for c in ORDEN_CAT], esperado)
chequeo("totales por modelo (Ge/Cl/GPT/Qw)", [int(tab.loc["Total", c]) for c in ["Gemini", "Claude", "GPT-4o", "Qwen"]], [9, 36, 96, 108])
chequeo("método (auto, paso, juicio)", [int((CWE.metodo == x).sum()) for x in ("automatico", "paso_harness", "juicio")], [110, 88, 51])

# %% 3. (b) Taxonomía final por nivel de complejidad y por estrategia
titulo("3. TAXONOMÍA POR NIVEL DE COMPLEJIDAD Y POR ESTRATEGIA")
niv = pd.crosstab(CWE.categoria_plc, CWE.nivel).reindex(index=ORDEN_CAT, columns=NIVELES + ["Complementaria"]).fillna(0).astype(int)
est = pd.crosstab(CWE.categoria_plc, CWE.estrategia).reindex(index=ORDEN_CAT, columns=["zero_shot", "few_shot"]).fillna(0).astype(int)
x = pd.concat([niv, est], axis=1)
x.columns = ["Básico", "Intermedio", "Avanzado", "Complem.", "Zero-shot", "Few-shot"]
x.index = [NOMBRE_CAT[c] for c in x.index]
x.loc["Total"] = x.sum()
print(x.to_string())
print("\n  % de los fallos de cada nivel:")
print((100.0 * niv / niv.sum()).round(1).rename(index=NOMBRE_CAT).to_string())
print("\n  Categoría por modelo y estrategia:")
mx = pd.crosstab(CWE.categoria_plc, [CWE.Modelo, CWE.estrategia]).reindex(ORDEN_CAT).fillna(0).astype(int)
print(mx.rename(index=NOMBRE_CAT).to_string())
print()
chequeo("fallos por nivel (B, I, A, C)", [int(niv[c].sum()) for c in niv.columns], [53, 88, 92, 16])
chequeo("fallos por estrategia (zero, few)", [int(est[c].sum()) for c in est.columns], [133, 116])

# %% 4. (c) Concordancia DeepSeek-Claude en las 51 clasificaciones por juicio
titulo("4. CONCORDANCIA DEEPSEEK (OFICIAL) - CLAUDE (SEGUNDO EVALUADOR), 51 CASOS POR JUICIO")
a, b = CONC.categoria_claude.astype(str), CONC.cat_deepseek.astype(str)
n = len(CONC)
acuerdo = int((a == b).sum())
cats = sorted(set(a) | set(b))
po = acuerdo / n
pe = sum((a == c).mean() * (b == c).mean() for c in cats)
kappa = (po - pe) / (1 - pe)
print("  Acuerdo: %s | kappa de Cohen = %.2f (p_o = %.3f, p_e = %.3f)" % (pct(acuerdo, n), kappa, po, pe))
print("\n  Matriz de confusión (filas Claude, columnas DeepSeek):")
print(pd.crosstab(a.rename("Claude"), b.rename("DeepSeek"), margins=True, margins_name="Total").to_string())
print("\n  Desacuerdos:")
for _, r in CONC[a != b].iterrows():
    print("    %s %-7s %s %-9s %s: Claude = %s, DeepSeek = %s"
          % (r.codigo, CORTO.get(r.modelo, r.modelo), r.tarea, r.estrategia, r.ejec, r.categoria_claude, r.cat_deepseek))
print("\n  Desacuerdos por tarea:", CONC[a != b].tarea.value_counts().to_dict())
print()
chequeo("acuerdo (de 51)", acuerdo, 46)
chequeo("kappa de Cohen (2 decimales)", round(kappa, 2), 0.79)

# %% 5. (d) Hipótesis, componente de complejidad: descriptiva y Cochran-Armitage
titulo("5. HIPÓTESIS - COMPLEJIDAD: DESCRIPTIVA POR NIVEL Y COCHRAN-ARMITAGE (referencia)")
print("  %-10s %-24s %-24s %-24s" % ("", "Básico", "Intermedio", "Avanzado"))
for var, nom in (("c1_pasa", "C1"), ("c2_compila", "C2")):
    for m in MODELOS + ["GLOBAL"]:
        s = G if m == "GLOBAL" else G[G.modelo == m]
        cel = [pct(int(s[s.nivel == nv][var].sum()), int((s.nivel == nv).sum())) for nv in NIVELES]
        print("  %-3s %-6s %-24s %-24s %-24s" % (nom, CORTO.get(m, m), cel[0], cel[1], cel[2]))
for m in MODELOS + ["GLOBAL"]:
    s = G if m == "GLOBAL" else G[G.modelo == m]
    print("  Tot %-6s %-24s %-24s %-24s" % ((CORTO.get(m, m),) + tuple("%.2f" % s[s.nivel == nv].total.mean() for nv in NIVELES)))


def cochran_armitage(k, n, s=(0, 1, 2)):
    k, n, s = map(np.asarray, (k, n, s))
    N = n.sum()
    pbar = k.sum() / N
    t = (s * (k - n * pbar)).sum()
    var = pbar * (1 - pbar) * ((n * s ** 2).sum() - (n * s).sum() ** 2 / N)
    z = t / math.sqrt(var) if var > 0 else float("nan")
    return z, 2 * norm.sf(abs(z))


print("\n  Cochran-Armitage (respuesta como unidad; supone independencia):")
for var, nom in (("c1_pasa", "C1"), ("c2_compila", "C2")):
    for m in MODELOS + ["GLOBAL"]:
        s = G if m == "GLOBAL" else G[G.modelo == m]
        kk = [int(s[s.nivel == nv][var].sum()) for nv in NIVELES]
        nn = [int((s.nivel == nv).sum()) for nv in NIVELES]
        z, p = cochran_armitage(kk, nn)
        print("    %-3s %-7s Z = %6.2f   p = %.2g" % (nom, CORTO.get(m, m), z, p))
print()
chequeo("C1 global por nivel (B, I, A)", [int(G[G.nivel == nv].c1_pasa.sum()) for nv in NIVELES], [139, 104, 52])
chequeo("C2 global por nivel (B, I, A)", [int(G[G.nivel == nv].c2_compila.sum()) for nv in NIVELES], [189, 178, 80])

# %% 6. (d) Hipótesis, complejidad: Jonckheere-Terpstra con la tarea como unidad
titulo("6. HIPÓTESIS - COMPLEJIDAD: JONCKHEERE-TERPSTRA POR PERMUTACIÓN (22 TAREAS) Y TAU-B")
print("  %d permutaciones, semilla %d, p unilateral para tendencia decreciente" % (NPERM, SEMILLA))


def jt_perm(valores, grupos, nperm=NPERM, semilla=SEMILLA):
    """Jonckheere-Terpstra para tendencia DECRECIENTE (grupos 0 < 1 < 2):
    pares (x en nivel menor, y en nivel mayor) con x > y, más 0.5 por empate.
    p unilateral por permutación de las etiquetas de nivel entre tareas."""
    v = np.asarray(valores, float)
    g = np.asarray(grupos, int)
    gt = (v[:, None] > v[None, :]).astype(float) + 0.5 * (v[:, None] == v[None, :])
    obs = float(((g[:, None] < g[None, :]) * gt).sum())
    rng = np.random.default_rng(semilla)
    cnt = 0
    for _ in range(max(1, nperm // 1000)):
        P = rng.permuted(np.tile(g, (1000, 1)), axis=1)
        menor = (P[:, :, None] < P[:, None, :]).astype(float)
        cnt += int(((menor * gt[None, :, :]).sum(axis=(1, 2)) >= obs - 1e-9).sum())
    return obs, (cnt + 1) / (nperm + 1)


JT = {}
for var, nom in (("c1_pasa", "C1"), ("c2_compila", "C2"), ("total", "Tot")):
    for m in MODELOS + ["GLOBAL"]:
        s = G if m == "GLOBAL" else G[G.modelo == m]
        tt = s.groupby("tarea").agg(v=(var, "mean"), g=("nivel_ord", "first"))
        jt, pjt = jt_perm(tt.v.values, tt.g.values)
        tau, ptau = kendalltau(tt.g.values, tt.v.values)
        JT[(nom, CORTO.get(m, m))] = pjt
        print("  %-3s %-7s JT = %6.1f  p_perm = %.4f | tau-b = %+.2f  p = %.2g" % (nom, CORTO.get(m, m), jt, pjt, tau, ptau))
tt = G.groupby("tarea").agg(c1=("c1_pasa", "sum"), nivel=("nivel", "first"))
print("\n  Aciertos del criterio 1 por tarea (de 24):")
for nv in NIVELES:
    z = tt[tt.nivel == nv]
    print("    %-10s %s" % (nv, " ".join("%s=%d" % (t, c) for t, c in z.c1.items())))
print("\n  Sensibilidad sin A1 (INC-33): C1 avanzado %s" % pct(int(G[(G.nivel == "Avanzado") & (G.tarea != "A1")].c1_pasa.sum()), 120))
print()
if NPERM == 200000:
    chequeo("JT p C1 Claude (0.0115; en la tesis 0.012)", round(JT[("C1", "Claude")], 4), 0.0115)
    chequeo("JT p C2 Claude", round(JT[("C2", "Claude")], 4), 0.0020)
    chequeo("JT p Tot Gemini", round(JT[("Tot", "Gemini")], 2), 0.18)
    chequeo("JT p global < 0.001 (C1, C2, Tot)", all(JT[(v, "GLOBAL")] < 0.001 for v in ("C1", "C2", "Tot")), True)
else:
    print("  (con NPERM distinto de 200 000 los p de permutación varían en el tercer decimal; no se comparan)")

# %% 7. (d) Hipótesis, componente de estrategia: few-shot frente a zero-shot
titulo("7. HIPÓTESIS - ESTRATEGIA: FEW-SHOT FRENTE A ZERO-SHOT (McNEMAR EXACTO, HOLM, WILCOXON)")


def holm(ps):
    orden = sorted(range(len(ps)), key=lambda i: ps[i])
    adj, ant = [0.0] * len(ps), 0.0
    for j, i in enumerate(orden):
        ant = max(ant, min(1.0, (len(ps) - j) * ps[i]))
        adj[i] = ant
    return adj


def mcnemar(a, b):
    sa = int(((a == 1) & (b == 0)).sum())
    sb = int(((a == 0) & (b == 1)).sum())
    return sa, sb, (p_binom(sa, sa + sb) if sa + sb else 1.0)


def pares(s, var):
    Z = s[s.estrategia == "zero_shot"].set_index(["modelo", "tarea", "ejec"])[var]
    F = s[s.estrategia == "few_shot"].set_index(["modelo", "tarea", "ejec"])[var].reindex(Z.index)
    return Z, F


HOLM = {}
for var, nom in (("c1_pasa", "Criterio 1"), ("c2_compila", "Criterio 2")):
    print("\n  %s (pareado por modelo x tarea x ejecución; Wilcoxon sobre aciertos por celda)" % nom)
    filas = []
    for m in MODELOS + ["GLOBAL"]:
        s = D if m == "GLOBAL" else D[D.modelo == m]
        Z, F = pares(s, var)
        a_, b_, p = mcnemar(Z.values, F.values)
        dz = (F.groupby(level=[0, 1]).sum() - Z.groupby(level=[0, 1]).sum()).values
        pw = wilcoxon(dz).pvalue if np.any(dz) else 1.0
        filas.append((m, int(Z.sum()), int(F.sum()), len(Z), a_, b_, p, pw))
    adj = holm([f[6] for f in filas[:4]]) + [float("nan")]
    for (m, z, f, nn, a_, b_, p, pw), pa in zip(filas, adj):
        HOLM[(nom, CORTO.get(m, m))] = pa
        print("    %-7s zero %-19s few %-19s solo zero %2d, solo few %2d  p = %.3g  p_Holm = %s  Wilcoxon p = %.3g"
              % (CORTO.get(m, m), pct(z, nn), pct(f, nn), a_, b_, p, "-" if math.isnan(pa) else "%.3g" % pa, pw))
print("\n  Total de la rúbrica (Wilcoxon pareado por tarea x ejecución)")
for m in MODELOS + ["GLOBAL"]:
    s = D if m == "GLOBAL" else D[D.modelo == m]
    Z, F = pares(s, "total")
    d = (F - Z).values
    print("    %-7s zero %.2f  few %.2f  dif %+.2f  Wilcoxon p = %.2g" % (CORTO.get(m, m), Z.mean(), F.mean(), d.mean(), wilcoxon(d).pvalue))
s = D[D.modelo != "gpt-4o-2024-08-06"]
Z, F = pares(s, "c1_pasa")
a_, b_, p_singpt = mcnemar(Z.values, F.values)
print("\n  Global sin GPT-4o, criterio 1: zero %s, few %s, p = %.2f" % (pct(int(Z.sum()), len(Z)), pct(int(F.sum()), len(F)), p_singpt))
print()
Zg, Fg = pares(D, "c1_pasa")
chequeo("C1 global zero / few (de 300)", (int(Zg.sum()), int(Fg.sum())), (167, 184))
Zg, Fg = pares(D, "total")
chequeo("Total rúbrica zero / few", (round(float(Zg.mean()), 2), round(float(Fg.mean()), 2)), (9.56, 10.17))
chequeo("p de Holm C2 Qwen", round(HOLM[("Criterio 2", "Qwen")], 3), 0.125)
chequeo("p sin GPT-4o (C1)", round(p_singpt, 2), 0.77)

# %% 7b. (d, OPCIONAL) Regresión GEE por nivel, clúster = tarea (requiere statsmodels)
titulo("7b. OPCIONAL - GEE (clúster = tarea; varianza robusta con corrección de sesgo)")
try:
    import statsmodels.api as sm
    from statsmodels.genmod.generalized_estimating_equations import GEE
    from statsmodels.genmod.cov_struct import Exchangeable

    def gee(datos, y, xs, familia):
        X = sm.add_constant(pd.get_dummies(datos[xs], drop_first=True, dtype=float))
        mod = GEE(datos[y].astype(float), X, groups=datos["tarea"], family=familia, cov_struct=Exchangeable())
        try:
            res = mod.fit(cov_type="bias_reduced")
        except Exception:
            res = mod.fit(cov_type="robust")
        return res.params["nivel_ord"], res.bse["nivel_ord"], res.pvalues["nivel_ord"]

    for var, nom in (("c1_pasa", "C1"), ("c2_compila", "C2")):
        b, se, p = gee(G, var, ["nivel_ord", "modelo", "estrategia"], sm.families.Binomial())
        print("  %-3s GLOBAL  OR por nivel = %.2f [%.2f; %.2f]  p = %.2g" % (nom, math.exp(b), math.exp(b - 1.96 * se), math.exp(b + 1.96 * se), p))
    b, se, p = gee(G, "total", ["nivel_ord", "modelo", "estrategia"], sm.families.Gaussian())
    print("  Tot GLOBAL  pendiente = %+.2f puntos/nivel [%+.2f; %+.2f]  p = %.2g" % (b, b - 1.96 * se, b + 1.96 * se, p))
except ImportError:
    print("  statsmodels no está instalado: celda omitida (no afecta a las demás).")

# %% 8. (e) Consistencia entre las tres ejecuciones de cada celda (sección 4.4.5)
titulo("8. CONSISTENCIA ENTRE EJECUCIONES (200 celdas de código: modelo x tarea x estrategia)")


def wilson(k, n, z=1.959964):
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return 100 * (c - h), 100 * (c + h)


cel = T.groupby(["modelo", "tarea", "estrategia"])
assert cel.size().eq(3).all() and len(cel) == 200
CONS = {}
for campo, nom in (("c2_compila", "CRITERIO 2 (compila)"), ("c1_pasa", "CRITERIO 1 (pasa el banco de prueba)")):
    suma = cel[campo].sum()
    print("\n  %s" % nom)
    print("  %-8s %5s %5s %5s %5s | %-20s | %s" % ("modelo", "3/3", "2/3", "1/3", "0/3", "celdas unánimes", "acierta las 3 si acierta alguna [IC 95 %]"))
    for m in MODELOS + ["GLOBAL"]:
        v = suma if m == "GLOBAL" else suma.xs(m, level="modelo")
        c = v.value_counts().reindex([3, 2, 1, 0], fill_value=0)
        nn = int(c.sum())
        una = int(c[3] + c[0])
        alguna = int(c[3] + c[2] + c[1])
        lo, hi = wilson(int(c[3]), alguna)
        CONS[(campo, CORTO.get(m, m))] = (int(c[3]), int(c[2]), int(c[1]), int(c[0]))
        print("  %-8s %5d %5d %5d %5d | %-20s | %s [%.1f; %.1f]" % (CORTO.get(m, m), c[3], c[2], c[1], c[0], pct(una, nn), pct(int(c[3]), alguna), lo, hi))
print("\n  Celdas mixtas del criterio 1 (1/3 o 2/3):")
suma = cel["c1_pasa"].sum()
for m in MODELOS:
    v = suma.xs(m, level="modelo")
    mix = ["%s-%s(%d/3)" % (t, "Z" if e == "zero_shot" else "F", k) for (t, e), k in v.items() if 0 < k < 3]
    print("    %-7s %2d: %s" % (CORTO[m], len(mix), " ".join(sorted(mix))))
# Determinismo del texto (opcional: requiere las 720 respuestas crudas en data/definitivo)
crudo = os.path.join(REPO, "data", "definitivo")
if os.path.isdir(crudo):
    import hashlib
    print("\n  Texto de la respuesta: respuestas distintas entre las 3 ejecuciones (60 celdas por modelo)")
    for m in MODELOS:
        base_m = os.path.join(crudo, m)
        if not os.path.isdir(base_m):
            continue
        cnt = {1: 0, 2: 0, 3: 0}
        for t in sorted(os.listdir(base_m)):
            for e in ("zero_shot", "few_shot"):
                hs = set()
                for j in (1, 2, 3):
                    with open(os.path.join(base_m, t, e, "ejec_%d.st" % j), "rb") as fh:
                        hs.add(hashlib.sha256(fh.read()).hexdigest())
                cnt[len(hs)] += 1
        print("    %-7s 3 iguales %2d | 2 iguales %2d | 3 distintas %2d" % (CORTO[m], cnt[1], cnt[2], cnt[3]))
else:
    print("\n  (No se encontró data/definitivo: se omite la comparación de textos.)")
print()
chequeo("C1 global celdas 3/2/1/0", CONS[("c1_pasa", "GLOBAL")], (94, 28, 13, 65))
chequeo("C2 global celdas 3/2/1/0", CONS[("c2_compila", "GLOBAL")], (163, 11, 7, 19))

# %% 9. Resumen de verificación
titulo("9. RESUMEN DE VERIFICACIÓN CONTRA LAS CIFRAS DE LA VERSIÓN 0.3")
ok = sum(1 for _, b in CHEQUEOS if b)
print("  %d de %d comprobaciones coinciden con lo reportado en la tesis." % (ok, len(CHEQUEOS)))
for d_, b in CHEQUEOS:
    if not b:
        print("  NO COINCIDE: %s" % d_)
