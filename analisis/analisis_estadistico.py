# -*- coding: utf-8 -*-
"""
Análisis estadístico del experimento — tesis LLMs + PLC (FIE-UTP).

Pensado para abrirse en Spyder y ejecutarse celda a celda (#%%, Ctrl+Enter),
o completo desde la terminal (lo que usa el agente `analista`):

    python analisis/analisis_estadistico.py \
        --log data/raw/log.jsonl \
        --resultados data/results/resultados_sintaxis_blark.csv \
        --metrica parsea

Entrada
  --log         log.jsonl del runner (dato primario: modelo, tarea, nivel, tipo,
                estrategia, ejecución, tokens, latencia).
  --resultados  CSV con una fila por respuesta y columnas modelo, tarea,
                estrategia, ejecucion y la métrica binaria (1 = éxito).
                · sintaxis (blark):  --metrica parsea
                · corrección funcional (harness): --metrica veredicto_ok
                  (se deriva de la columna `veredicto`: 1 = aprueba)
  --retest      (opcional) segundo CSV de resultados con la misma métrica, para
                el test-retest piloto ↔ definitivo (kappa de Cohen).

Salida (en analisis/salidas/<fecha>_<métrica>/): tablas CSV, figuras PNG a
300 dpi y RESUMEN.md con cada prueba, su n, estadístico, p e intervalo.

Pruebas
  1. Tasa de éxito con IC de Wilson al 95 % (modelo × estrategia, nivel, tipo).
  2. McNemar exacto zero-shot vs few-shot por modelo, pareado por tarea×ejecución.
  3. Entre modelos: Q de Cochran (k ≥ 3) + McNemar por pares con Holm;
     con k = 2, McNemar directo. Pareado por tarea×estrategia×ejecución.
  4. Regresión logística GEE (grupos = tarea) si no hay separación perfecta.
  5. Kappa de Cohen para test-retest (si se pasa --retest).

Regla: este script no excluye, recodifica ni imputa nada. Si una prueba no es
aplicable, lo dice y sigue.
"""

#%% 0. Configuración — en Spyder, edita CONFIG y ejecuta celda a celda
import argparse
import datetime as dt
import json
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
import matplotlib.pyplot as plt

AQUI = Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()
RAIZ = AQUI.parent

CONFIG = {
    "log": RAIZ / "data" / "raw" / "log.jsonl",
    "resultados": RAIZ / "data" / "results_codesys" / "compilacion_piloto.csv",
    "metrica": "compila",
    "retest": None,
    "salida": AQUI / "salidas",
    "alfa": 0.05,
}

# Descripcion fija: en Spyder, al ejecutar por celdas, __doc__ no es el docstring del archivo.
ap = argparse.ArgumentParser(description="Analisis estadistico del experimento (tesis LLMs + PLC)")
ap.add_argument("--log")
ap.add_argument("--resultados")
ap.add_argument("--metrica")
ap.add_argument("--retest")
ap.add_argument("--salida")
args, _ = ap.parse_known_args()  # parse_known_args: Spyder pasa argumentos propios
for k in ("log", "resultados", "metrica", "retest", "salida"):
    v = getattr(args, k)
    if v:
        CONFIG[k] = Path(v) if k != "metrica" else v

SAL = Path(CONFIG["salida"]) / f"{dt.datetime.now():%Y%m%d_%H%M%S}_{CONFIG['metrica']}"
SAL.mkdir(parents=True, exist_ok=True)
RESUMEN = []  # líneas de RESUMEN.md


def nota(texto=""):
    print(texto)
    RESUMEN.append(texto)


# Paleta categórica validada (contraste, daltonismo): zero-shot / few-shot
COLOR_ESTRATEGIA = {"zero_shot": "#2a78d6", "few_shot": "#eb6834"}
ETQ_ESTRATEGIA = {"zero_shot": "Zero-shot", "few_shot": "Few-shot"}
matplotlib.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 9, "axes.spines.top": False,
    "axes.spines.right": False, "axes.edgecolor": "#8a8a85", "axes.labelcolor": "#2b2b29",
    "xtick.color": "#4a4a46", "ytick.color": "#4a4a46", "axes.grid": True,
    "grid.color": "#e6e5e0", "grid.linewidth": 0.6, "axes.axisbelow": True,
    "savefig.dpi": 300, "savefig.bbox": "tight",
})

nota(f"# Análisis estadístico — métrica `{CONFIG['metrica']}`")
nota(f"Generado: {dt.datetime.now():%Y-%m-%d %H:%M}  ·  log: `{CONFIG['log']}`  ·  resultados: `{CONFIG['resultados']}`\n")


#%% 1. Carga y unión de datos
def clave_modelo(s):
    return str(s).replace(":", "_")


log = pd.read_json(CONFIG["log"], lines=True)
log["modelo"] = log["modelo_config"].map(clave_modelo)

res = pd.read_csv(CONFIG["resultados"])
res["modelo"] = res["modelo"].map(clave_modelo)
metrica = CONFIG["metrica"]
if metrica == "veredicto_ok" and "veredicto_ok" not in res.columns:
    res["veredicto_ok"] = (pd.to_numeric(res["veredicto"], errors="coerce") == 1).astype(int)
if metrica not in res.columns:
    raise SystemExit(f"La columna '{metrica}' no existe en {CONFIG['resultados']}. Columnas: {list(res.columns)}")

LLAVE = ["modelo", "tarea", "estrategia", "ejecucion"]
df = log.merge(res[LLAVE + [metrica]], on=LLAVE, how="left", validate="one_to_one")
faltan = df[metrica].isna().sum()
df["exito"] = df[metrica]

nota("## 1. Datos")
nota(f"Registros en el log: {len(log)} · con resultado: {len(df) - faltan} · sin resultado: {faltan}")
if faltan:
    nota("  (Las respuestas sin resultado quedan fuera de cada prueba y se listan en `sin_resultado.csv`; no se imputan.)")
    df[df[metrica].isna()][LLAVE].to_csv(SAL / "sin_resultado.csv", index=False)
d = df.dropna(subset=["exito"]).copy()
d["exito"] = d["exito"].astype(int)
MODELOS = sorted(d["modelo"].unique())
nota(f"Modelos: {', '.join(MODELOS)} · tareas: {d['tarea'].nunique()} · estrategias: {', '.join(sorted(d['estrategia'].unique()))}\n")

desc = (d.groupby(["modelo", "estrategia"])
          .agg(n=("exito", "size"), tokens_salida_media=("tokens_salida", "mean"),
               latencia_media_s=("latencia_s", "mean"))
          .round(2).reset_index())
desc.to_csv(SAL / "descriptivos.csv", index=False)
print(desc.to_string(index=False))


#%% 2. Tasa de éxito con IC de Wilson al 95 %
def wilson(k, n, alfa=0.05):
    if n == 0:
        return (np.nan, np.nan)
    z = stats.norm.ppf(1 - alfa / 2)
    p = k / n
    den = 1 + z**2 / n
    centro = (p + z**2 / (2 * n)) / den
    medio = z * np.sqrt(p * (1 - p) / n + z**2 / (4 * n**2)) / den
    return (max(0.0, centro - medio), min(1.0, centro + medio))


def tabla_tasas(grupos):
    t = d.groupby(grupos)["exito"].agg(k="sum", n="size").reset_index()
    t["tasa"] = t["k"] / t["n"]
    ic = t.apply(lambda r: wilson(r["k"], r["n"], CONFIG["alfa"]), axis=1)
    t["ic_inf"] = [a for a, _ in ic]
    t["ic_sup"] = [b for _, b in ic]
    return t


nota("## 2. Tasa de éxito (IC de Wilson al 95 %)")
tasas = {}
for nombre, g in {"global": ["modelo"], "modelo_estrategia": ["modelo", "estrategia"],
                  "modelo_nivel": ["modelo", "nivel"], "tipo": ["tipo", "estrategia"]}.items():
    t = tabla_tasas(g)
    t.to_csv(SAL / f"tasas_{nombre}.csv", index=False)
    tasas[nombre] = t
kt, nt = int(d["exito"].sum()), len(d)
a, b = wilson(kt, nt)
nota(f"Global: {kt}/{nt} = {kt/nt:.1%} (IC 95 %: {a:.1%}–{b:.1%})")
for _, r in tasas["modelo_estrategia"].iterrows():
    nota(f"- {r['modelo']} · {ETQ_ESTRATEGIA.get(r['estrategia'], r['estrategia'])}: "
         f"{int(r['k'])}/{int(r['n'])} = {r['tasa']:.1%} (IC {r['ic_inf']:.1%}–{r['ic_sup']:.1%})")
nota("")


#%% 3. McNemar exacto: zero-shot vs few-shot dentro de cada modelo
def mcnemar_exacto(x, y):
    """x, y: arreglos 0/1 pareados. Devuelve dict con b, c, p exacta y OR (con 0.5)."""
    x, y = np.asarray(x), np.asarray(y)
    b = int(((x == 1) & (y == 0)).sum())
    c = int(((x == 0) & (y == 1)).sum())
    if b + c == 0:
        return {"b": b, "c": c, "p": np.nan, "or": np.nan, "nota": "sin pares discordantes: no aplicable"}
    p = stats.binomtest(min(b, c), b + c, 0.5).pvalue
    return {"b": b, "c": c, "p": p, "or": (c + 0.5) / (b + 0.5), "nota": ""}


nota("## 3. Zero-shot vs few-shot por modelo (McNemar exacto)")
nota("b = aciertos solo en zero-shot · c = aciertos solo en few-shot · OR = c/b (corrección 0.5)")
filas = []
for m in MODELOS:
    w = (d[d["modelo"] == m].pivot_table(index=["tarea", "ejecucion"], columns="estrategia",
                                          values="exito", aggfunc="first").dropna())
    if not {"zero_shot", "few_shot"} <= set(w.columns):
        continue
    r = mcnemar_exacto(w["zero_shot"], w["few_shot"])
    dif = w["few_shot"].mean() - w["zero_shot"].mean()
    filas.append({"modelo": m, "pares": len(w), **r, "dif_fs_menos_zs": dif})
    ptxt = "n/a" if np.isnan(r["p"]) else f"{r['p']:.4f}"
    nota(f"- {m}: pares={len(w)}, b={r['b']}, c={r['c']}, Δ(FS−ZS)={dif:+.1%}, p={ptxt}"
         + (f", OR={r['or']:.2f}" if not np.isnan(r["or"]) else "") + (f" — {r['nota']}" if r["nota"] else ""))
pd.DataFrame(filas).to_csv(SAL / "mcnemar_estrategia.csv", index=False)
nota("")


#%% 4. Comparación entre modelos: Q de Cochran + McNemar por pares (Holm)
def cochran_q(matriz):
    x = np.asarray(matriz, dtype=int)
    n, k = x.shape
    col, fila = x.sum(axis=0), x.sum(axis=1)
    N = x.sum()
    den = k * N - (fila**2).sum()
    if den == 0:
        return np.nan, k - 1, np.nan
    q = (k - 1) * (k * (col**2).sum() - N**2) / den
    return q, k - 1, stats.chi2.sf(q, k - 1)


def holm(pvals):
    p = np.asarray(pvals, dtype=float)
    orden = np.argsort(p)
    ajust = np.empty_like(p)
    acum = 0.0
    for i, j in enumerate(orden):
        acum = max(acum, min(1.0, (len(p) - i) * p[j]))
        ajust[j] = acum
    return ajust


nota("## 4. Comparación entre modelos (pareada por tarea × estrategia × ejecución)")
anchos = d.pivot_table(index=["tarea", "estrategia", "ejecucion"], columns="modelo",
                       values="exito", aggfunc="first").dropna()
k = anchos.shape[1]
if k >= 3:
    q, gl, p = cochran_q(anchos.values)
    nota(f"Q de Cochran: Q={q:.2f}, gl={gl}, p={p:.4g}, bloques completos={len(anchos)}")
if k >= 2:
    pares, ps = [], []
    for i in range(k):
        for j in range(i + 1, k):
            mi, mj = anchos.columns[i], anchos.columns[j]
            r = mcnemar_exacto(anchos[mi], anchos[mj])
            pares.append({"modelo_a": mi, "modelo_b": mj, **r,
                          "tasa_a": anchos[mi].mean(), "tasa_b": anchos[mj].mean()})
            ps.append(r["p"])
    tp = pd.DataFrame(pares)
    validos = ~tp["p"].isna()
    tp["p_holm"] = np.nan
    if validos.any():
        tp.loc[validos, "p_holm"] = holm(tp.loc[validos, "p"])
    tp.to_csv(SAL / "mcnemar_modelos.csv", index=False)
    for _, r in tp.iterrows():
        ptxt = "n/a" if np.isnan(r["p"]) else f"p={r['p']:.4f}, p_Holm={r['p_holm']:.4f}"
        nota(f"- {r['modelo_a']} ({r['tasa_a']:.1%}) vs {r['modelo_b']} ({r['tasa_b']:.1%}): "
             f"b={r['b']}, c={r['c']}, {ptxt}" + (f" — {r['nota']}" if r["nota"] else ""))
else:
    nota("Un solo modelo con resultados: no hay comparación entre modelos.")
nota("")


#%% 5. Regresión logística GEE (efectos de modelo, estrategia y nivel; grupos = tarea)
nota("## 5. Regresión logística GEE")
try:
    import statsmodels.api as sm
    import statsmodels.formula.api as smf
    celdas = d.groupby(["modelo", "estrategia"])["exito"].mean()
    separacion = celdas[(celdas == 0) | (celdas == 1)]
    if len(separacion):
        nota("No estimable de forma fiable: hay separación perfecta en "
             + ", ".join(f"{a}·{b} = {v:.0%}" for (a, b), v in separacion.items())
             + ". Los odds ratios de esas celdas tienden a infinito; se reportan las pruebas exactas de las secciones 3 y 4.")
    else:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            formula = "exito ~ C(modelo) + C(estrategia, Treatment('zero_shot'))"
            if d["nivel"].nunique() > 1:
                formula += " + C(nivel)"
            gee = smf.gee(formula, groups="tarea", data=d, family=sm.families.Binomial(),
                          cov_struct=sm.cov_struct.Exchangeable()).fit()
        tabla = pd.DataFrame({"OR": np.exp(gee.params), "IC_inf": np.exp(gee.conf_int()[0]),
                              "IC_sup": np.exp(gee.conf_int()[1]), "p": gee.pvalues}).round(4)
        tabla.to_csv(SAL / "gee_odds_ratios.csv")
        nota(f"Fórmula: `{formula}` · grupos = tarea (n={d['tarea'].nunique()}), correlación intercambiable")
        nota("```\n" + tabla.to_string() + "\n```")
except ImportError:
    nota("statsmodels no está instalado: `pip install statsmodels` (en Anaconda ya viene).")
nota("")


#%% 6. Test-retest: kappa de Cohen piloto ↔ definitivo (opcional)
if CONFIG["retest"]:
    nota("## 6. Test-retest (kappa de Cohen)")
    r2 = pd.read_csv(CONFIG["retest"])
    r2["modelo"] = r2["modelo"].map(clave_modelo)
    if metrica == "veredicto_ok" and "veredicto_ok" not in r2.columns:
        r2["veredicto_ok"] = (pd.to_numeric(r2["veredicto"], errors="coerce") == 1).astype(int)
    c = d[LLAVE + ["exito"]].merge(r2[LLAVE + [metrica]], on=LLAVE).dropna()
    for m, g in c.groupby("modelo"):
        x, y = g["exito"].astype(int), g[metrica].astype(int)
        po = (x == y).mean()
        pe = x.mean() * y.mean() + (1 - x.mean()) * (1 - y.mean())
        kappa = np.nan if pe == 1 else (po - pe) / (1 - pe)
        nota(f"- {m}: n={len(g)}, acuerdo={po:.1%}, kappa={kappa:.3f}"
             + (" (sin variación en ambos: kappa no definido; el acuerdo es el dato)" if np.isnan(kappa) else ""))
    nota("")


#%% 7. Figuras (300 dpi)
nota("## Figuras")
t = tasas["modelo_estrategia"]
estrategias = [e for e in ("zero_shot", "few_shot") if e in t["estrategia"].unique()]
fig, ax = plt.subplots(figsize=(6.4, 3.4))
ancho = 0.36
xs = np.arange(len(MODELOS))
for i, e in enumerate(estrategias):
    sub = t[t["estrategia"] == e].set_index("modelo").reindex(MODELOS)
    pos = xs + (i - (len(estrategias) - 1) / 2) * (ancho + 0.02)
    err = np.vstack([sub["tasa"] - sub["ic_inf"], sub["ic_sup"] - sub["tasa"]]) * 100
    ax.bar(pos, sub["tasa"] * 100, width=ancho, color=COLOR_ESTRATEGIA[e],
           label=ETQ_ESTRATEGIA[e], edgecolor="white", linewidth=1)
    ax.errorbar(pos, sub["tasa"] * 100, yerr=err, fmt="none", ecolor="#2b2b29", elinewidth=0.9, capsize=3)
    for x_, v, n_ in zip(pos, sub["tasa"], sub["n"]):
        if not np.isnan(v):
            ax.text(x_, 2, f"{v:.0%}", ha="center", va="bottom", fontsize=7.5, color="white", fontweight="bold")
ax.set_xticks(xs, MODELOS)
ax.set_ylim(0, 105)
ax.set_ylabel(f"Tasa de éxito — {metrica} (%)")
ax.grid(axis="x", visible=False)
ax.legend(frameon=False, ncols=len(estrategias), loc="upper left", bbox_to_anchor=(0, 1.12))
ax.set_title("Barras: IC de Wilson al 95 %", fontsize=8, color="#6b6b66", loc="right")
fig.savefig(SAL / "fig_exito_modelo_estrategia.png")
plt.show() if matplotlib.get_backend().lower() not in ("agg",) else plt.close(fig)
nota("- `fig_exito_modelo_estrategia.png`: tasa por modelo y estrategia con IC de Wilson.")

mapa = d.pivot_table(index="tarea", columns=["modelo", "estrategia"], values="exito", aggfunc="mean")
orden_cols = [(m, e) for m in MODELOS for e in ("zero_shot", "few_shot") if (m, e) in mapa.columns]
orden_tareas = sorted(mapa.index, key=lambda s: ("BIAC".index(s[0]) if s[0] in "BIAC" else 9, int(s[1:])))
mapa = mapa.reindex(index=orden_tareas, columns=orden_cols)
fig, ax = plt.subplots(figsize=(1.6 + 0.85 * mapa.shape[1], 0.9 + 0.24 * mapa.shape[0]))
azules = matplotlib.colors.LinearSegmentedColormap.from_list("azul", ["#f4f8fd", "#86b6ef", "#2a78d6", "#104281"])
im = ax.pcolormesh(mapa.values * 100, cmap=azules, vmin=0, vmax=100, edgecolors="white", linewidth=1.5)
ax.invert_yaxis()
etq_modelo = lambda m: m.replace("-2024-08-06", "").replace("claude-", "claude-\n").replace("coder_", "coder\n")
ax.set_xticks(np.arange(mapa.shape[1]) + 0.5,
              [f"{etq_modelo(m)}\n{ETQ_ESTRATEGIA.get(e, e)}" for m, e in mapa.columns], fontsize=6.5)
ax.set_yticks(np.arange(mapa.shape[0]) + 0.5, mapa.index, fontsize=7)
ax.tick_params(length=0)
ax.grid(False)
for sp in ax.spines.values():
    sp.set_visible(False)
for (i, j), v in np.ndenumerate(mapa.values):
    if not np.isnan(v):
        ax.text(j + 0.5, i + 0.5, f"{v*100:.0f}", ha="center", va="center", fontsize=6.5,
                color="white" if v > 0.6 else "#2b2b29")
cb = fig.colorbar(im, ax=ax, fraction=0.05, pad=0.03)
cb.set_label("% de éxito (3 ejecuciones)", fontsize=7)
cb.ax.tick_params(labelsize=7)
cb.outline.set_visible(False)
fig.savefig(SAL / "fig_mapa_tarea_modelo.png")
plt.show() if matplotlib.get_backend().lower() not in ("agg",) else plt.close(fig)
nota("- `fig_mapa_tarea_modelo.png`: % de éxito por tarea, modelo y estrategia.")


#%% 8. Exportar resumen
(SAL / "RESUMEN.md").write_text("\n".join(RESUMEN), encoding="utf-8")
(SAL / "parametros.json").write_text(json.dumps({k: str(v) for k, v in CONFIG.items()}, indent=2, ensure_ascii=False),
                                     encoding="utf-8")
print(f"\nSalidas en: {SAL}")
