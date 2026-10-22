# -*- coding: utf-8 -*-
"""c05_revision_deepseek.py — Revisión a ciegas de las 51 clasificaciones por juicio (decisión del autor 2026-10-13).

Compara la clasificación de DeepSeek (oficial, deepseek-v4-pro, sin ver la de Claude ni el modelo evaluado)
con la de Claude (segundo evaluador, juicio_llm.csv). Escribe juicio_deepseek.csv, que c02 usa como oficial.
Entradas: revision_deepseek/salida/lote_*.json, revision_deepseek/clave_sellada_NO_ENVIAR.csv, juicio_llm.csv
"""
import glob, json, os
import pandas as pd
from sklearn.metrics import cohen_kappa_score

AQUI = os.path.dirname(os.path.abspath(__file__))
R = os.path.join(AQUI, "revision_deepseek")
CWE = {"TEMPORIZACION": "CWE-670", "SECUENCIA": "CWE-670", "SEGURIDAD": "CWE-754",
       "INICIALIZACION": "CWE-665", "FLANCO": "CWE-372", "CALCULO": "CWE-682"}
ds = []
for f in sorted(glob.glob(os.path.join(R, "salida", "lote_*.json"))):
    ds += json.load(open(f, encoding="utf-8"))
ds = pd.DataFrame(ds).rename(columns={"categoria": "cat_deepseek", "justificacion": "just_deepseek"})
clave = pd.read_csv(os.path.join(R, "clave_sellada_NO_ENVIAR.csv"))
m = clave.merge(ds, on="codigo", how="left")
assert len(m) == 51 and m.cat_deepseek.notna().all(), "faltan clasificaciones de DeepSeek"
cl = pd.read_csv(os.path.join(AQUI, "juicio_llm.csv"))
m = m.merge(cl[["modelo", "tarea", "estrategia", "ejec", "categoria_plc"]], on=["modelo", "tarea", "estrategia", "ejec"])
assert (m.categoria_plc == m.categoria_claude).all()
acuerdo = (m.cat_deepseek == m.categoria_claude).mean()
k = cohen_kappa_score(m.categoria_claude, m.cat_deepseek)
print(f"Casos: {len(m)} | acuerdo DeepSeek-Claude: {(m.cat_deepseek == m.categoria_claude).sum()}/{len(m)} = {acuerdo:.1%} | kappa de Cohen = {k:.2f}")
print("\nMatriz de confusión (filas Claude, columnas DeepSeek):")
print(pd.crosstab(m.categoria_claude, m.cat_deepseek, margins=True))
print("\nDesacuerdos:")
for _, r in m[m.cat_deepseek != m.categoria_claude].iterrows():
    print(f" {r.codigo} {r.modelo} {r.tarea} {r.estrategia} {r.ejec}: Claude={r.categoria_claude} DeepSeek={r.cat_deepseek} | {r.just_deepseek}")
out = m[["modelo", "tarea", "estrategia", "ejec"]].copy()
out["categoria_plc"] = m.cat_deepseek
out["cwe_id"] = m.cat_deepseek.map(CWE)
out["justificacion"] = "DeepSeek (oficial, a ciegas): " + m.just_deepseek
out.to_csv(os.path.join(AQUI, "juicio_deepseek.csv"), index=False)
m.to_csv(os.path.join(AQUI, "concordancia_juicio_deepseek_claude.csv"), index=False)
print("\nEscrito juicio_deepseek.csv (oficial) y concordancia_juicio_deepseek_claude.csv")
