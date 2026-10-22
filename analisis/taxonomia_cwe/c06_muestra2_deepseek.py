# -*- coding: utf-8 -*-
"""Segunda muestra del mapa v2: compara la categoría del mapa con la lectura de Claude y con la de DeepSeek a ciegas.
Entradas: verificacion_mapa_pasos_v2.csv, revision_deepseek_muestra2/salida/lote_*.json y su clave sellada.
Salida: verificacion_mapa_pasos_v2_deepseek.csv y resumen en consola. Uso: python c06_muestra2_deepseek.py"""
import glob, json, os, math
import pandas as pd
AQUI = os.path.dirname(os.path.abspath(__file__)); R = os.path.join(AQUI, "revision_deepseek_muestra2")
k = ["modelo", "tarea", "estrategia", "ejec"]
ds = []
for f in sorted(glob.glob(os.path.join(R, "salida", "lote_*.json"))):
    ds += json.load(open(f, encoding="utf-8"))
ds = pd.DataFrame(ds).rename(columns={"categoria": "categoria_deepseek", "justificacion": "justificacion_deepseek"})
clave = pd.read_csv(os.path.join(R, "clave_sellada_NO_ENVIAR.csv"), encoding="utf-8-sig")
v = pd.read_csv(os.path.join(AQUI, "verificacion_mapa_pasos_v2.csv"))
m = v.merge(clave.merge(ds, on="codigo"), on=k)
assert len(m) == len(v) == 22, len(m)
def wilson(x, n, z=1.959964):
    p = x / n; d = 1 + z * z / n; c = (p + z * z / (2 * n)) / d; h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return 100 * p, 100 * (c - h), 100 * (c + h)
def kappa(a, b):
    cats = sorted(set(a) | set(b)); n = len(a); po = sum(x == y for x, y in zip(a, b)) / n
    pe = sum((list(a).count(c) / n) * (list(b).count(c) / n) for c in cats); return (po - pe) / (1 - pe)
for etiqueta, col1, col2 in [("mapa v2 vs DeepSeek", "categoria_mapa_v2", "categoria_deepseek"),
                             ("mapa v2 vs Claude", "categoria_mapa_v2", "categoria_codigo"),
                             ("Claude vs DeepSeek", "categoria_codigo", "categoria_deepseek")]:
    x = int((m[col1] == m[col2]).sum()); p, lo, hi = wilson(x, 22)
    print("%-20s %2d/22 = %.1f %% (IC 95 %% %.1f-%.1f) | kappa = %.2f" % (etiqueta, x, p, lo, hi, kappa(m[col1], m[col2])))
print("\nDesacuerdos con el mapa:")
print(m[m.categoria_mapa_v2 != m.categoria_deepseek][k + ["paso_primario", "categoria_mapa_v2", "categoria_codigo", "categoria_deepseek"]].to_string(index=False))
m.to_csv(os.path.join(AQUI, "verificacion_mapa_pasos_v2_deepseek.csv"), index=False)
