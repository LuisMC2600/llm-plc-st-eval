# -*- coding: utf-8 -*-
"""Analiza las fichas de evaluacion manual a ciegas (C1, C5, C6 y C2).

Lee lo que marcaron los evaluadores, lo descodifica con _SELLADO_asignacion_codigos.csv
y calcula las metricas fijadas ANTES de calificar (bitacora, 2026-10-07):
  diagnostico: tasa de deteccion sobre la clave, tasa de correccion valida, diagnostico
               completo (4 de 4), hallazgos adicionales validos y errores inventados;
  C2:          senales de E/S presentes, tipos validos, POU, justificacion, ambiguedades;
  concordancia entre evaluadores (kappa de Cohen) sobre la submuestra comun.
El analisis principal usa al evaluador 1. Este script NO califica nada: solo cuenta.
Uso (desde llm-plc-st-eval):
  python evaluacion_manual/analizar_fichas.py [ficha1.xlsx] [ficha2.xlsx] [carpeta_salida]"""
import csv, math, os, sys, collections
from openpyxl import load_workbook
AQUI = os.path.dirname(os.path.abspath(__file__))
F1 = sys.argv[1] if len(sys.argv) > 1 else os.path.join(AQUI, "Evaluador1", "Ficha_Evaluador1.xlsx")
F2 = sys.argv[2] if len(sys.argv) > 2 else os.path.join(AQUI, "Evaluador2", "Ficha_Evaluador2.xlsx")
SAL = sys.argv[3] if len(sys.argv) > 3 else os.path.join("data", "results")
MODELOS = ["gemini-3.1-pro-preview", "claude-sonnet-4-6", "gpt-4o-2024-08-06", "qwen2.5-coder_14b"]
DIAG = ["C1", "C5", "C6"]; FILA_ENC, FILA_1 = 4, 6
ASIG = {r["codigo"]: r for r in csv.DictReader(open(os.path.join(AQUI, "_SELLADO_asignacion_codigos.csv"), encoding="utf-8-sig"))}

def sn(v):
    v = ("" if v is None else str(v)).strip().upper()
    return {"S": 1, "SI": 1, "SÍ": 1, "N": 0, "NO": 0}.get(v, None)
def num(v):
    try: return int(float(v))
    except (TypeError, ValueError): return None

def leer(ruta):
    """Devuelve ({codigo: dict}, [faltantes]). Las celdas de formula no se usan: solo las entradas."""
    wb = load_workbook(ruta, data_only=True); datos, faltan = {}, []
    for t in DIAG + ["C2"]:
        ws = wb[t]
        for f in range(FILA_1, ws.max_row + 1):
            cod = ws.cell(row=f, column=1).value
            if not cod or cod == "EJEMPLO": continue
            v = lambda c: ws.cell(row=f, column=c).value
            d = {"codigo": cod, "tarea": t, "obs": v(12 if t != "C2" else 18) or ""}
            if t != "C2":
                d["det"] = [sn(v(c)) for c in (2, 4, 6, 8)]
                d["cor"] = [sn(v(c)) or 0 for c in (3, 5, 7, 9)]          # en blanco = no aplica = 0
                d["adic"], d["inv"] = num(v(10)), num(v(11))
                oblig = d["det"] + [d["adic"], d["inv"]]
            else:
                d["es"] = [sn(v(c)) for c in (2, 3, 4, 5, 6)]; d["tipos"] = sn(v(7)); d["pou"] = (v(8) or "").strip() if v(8) else None
                d["jus"] = sn(v(9)); d["amb"] = [sn(v(c)) for c in range(10, 16)]; d["adic"] = num(v(16)); d["codigo_st"] = sn(v(17))
                oblig = d["es"] + [d["tipos"], d["pou"], d["jus"]] + d["amb"] + [d["adic"], d["codigo_st"]]
            if any(x is None for x in oblig): faltan.append(cod)
            datos[cod] = d
    return datos, faltan

def wilson(k, n, z=1.959964):
    if n == 0: return (float("nan"), float("nan"))
    p = k / n; d = 1 + z*z/n; c = (p + z*z/(2*n)) / d; h = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n)) / d
    return max(0.0, 100*(c - h)), min(100.0, 100*(c + h))
def tasa(k, n):
    lo, hi = wilson(k, n); return "%3d/%3d = %5.1f %% [%5.1f; %5.1f]" % (k, n, 100*k/n if n else 0, lo, hi)
def kappa(a, b):
    n = len(a)
    if n == 0: return float("nan"), float("nan")
    po = sum(1 for x, y in zip(a, b) if x == y) / n
    pa, pb = sum(a) / n, sum(b) / n; pe = pa*pb + (1 - pa)*(1 - pb)
    return (1.0 if pe == 1 else (po - pe) / (1 - pe)), 100*po

E1, falt1 = leer(F1)
print("Evaluador 1: %d respuestas leidas, %d incompletas" % (len(E1), len(falt1)))
if falt1:
    por = collections.Counter(c.split("-")[0] for c in falt1)
    print("  FALTAN celdas obligatorias. Por tarea: " + ", ".join("%s %d" % kv for kv in sorted(por.items())) + ". Primeras: " + ", ".join(sorted(falt1)[:8])); print("  Completa la ficha y vuelve a ejecutar. No se calcula nada con fichas incompletas."); sys.exit(1)
assert set(E1) == set(ASIG), "los codigos de la ficha no coinciden con la asignacion sellada"
for c, d in E1.items(): d.update({k: ASIG[c][k] for k in ("modelo", "estrategia", "ejec", "truncada")})
R = list(E1.values()); D = [r for r in R if r["tarea"] in DIAG]; Q = [r for r in R if r["tarea"] == "C2"]

print("\n===== DIAGNOSTICO DE CODIGO (C1, C5, C6): %d respuestas, clave de 4 errores por tarea =====" % len(D))
def bloque(filas, etiqueta):
    n = len(filas); det = sum(sum(r["det"]) for r in filas); cor = sum(sum(r["cor"]) for r in filas); comp = sum(1 for r in filas if sum(r["det"]) == 4)
    inv = sum(r["inv"] for r in filas); adic = sum(r["adic"] for r in filas); con_inv = sum(1 for r in filas if r["inv"] > 0)
    print("  %-30s deteccion %s | correccion valida %s" % (etiqueta, tasa(det, 4*n), tasa(cor, 4*n)))
    print("  %-30s completo 4/4 %s | inventados: media %.2f, con alguno %d/%d | adicionales validos: media %.2f" % ("", tasa(comp, n), inv/n, con_inv, n, adic/n))
bloque(D, "GLOBAL")
for m in MODELOS: bloque([r for r in D if r["modelo"] == m], m)
for m in MODELOS:
    for e in ("zero_shot", "few_shot"): bloque([r for r in D if r["modelo"] == m and r["estrategia"] == e], m[:18] + " | " + e)
print("  -- por tarea y por error de la clave: detecciones de 24")
for t in DIAG:
    X = [r for r in D if r["tarea"] == t]
    print("     %s: " % t + "  ".join("E%d %2d" % (i + 1, sum(r["det"][i] for r in X)) for i in range(4)) + "   | por modelo (de 24 = 6 respuestas x 4 errores): " + "  ".join("%s %2d" % (m[:6], sum(sum(r["det"]) for r in X if r["modelo"] == m)) for m in MODELOS))

print("\n===== C2, DE REQUISITO AMBIGUO A ESPECIFICACION: %d respuestas (estudio de caso, n = 1 tarea) =====" % len(Q))
for m in MODELOS + ["TODOS"]:
    X = [r for r in Q if m in ("TODOS", r["modelo"])]; n = len(X)
    print("  %-26s E/S presentes %.2f de 5 | tipos validos %d/%d | justificacion coherente %d/%d | ambiguedades de la clave %.2f de 6 | adicionales %.2f | incluyo codigo %d/%d | POU: %s" % (
        m, sum(sum(r["es"]) for r in X)/n, sum(r["tipos"] for r in X), n, sum(r["jus"] for r in X), n, sum(sum(r["amb"]) for r in X)/n,
        sum(r["adic"] for r in X)/n, sum(r["codigo_st"] for r in X), n, dict(collections.Counter(r["pou"] for r in X))))
print("  -- ambiguedades de la clave, respuestas que las plantean (de %d): " % len(Q) + "  ".join("A%d %2d" % (i + 1, sum(r["amb"][i] for r in Q)) for i in range(6)))

os.makedirs(SAL, exist_ok=True)
with open(os.path.join(SAL, "evaluacion_manual_definitivo.csv"), "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.writer(fh)
    w.writerow(["codigo", "tarea", "modelo", "estrategia", "ejec", "truncada", "detectados", "correcciones_validas", "adicionales_validos", "errores_inventados",
                "es_presentes", "tipos_validos", "pou", "justificacion", "ambiguedades_clave", "incluyo_codigo", "detalle_items", "observaciones"])
    for r in sorted(R, key=lambda r: (r["tarea"], r["modelo"], r["estrategia"], r["ejec"])):
        if r["tarea"] != "C2":
            w.writerow([r["codigo"], r["tarea"], r["modelo"], r["estrategia"], r["ejec"], r["truncada"], sum(r["det"]), sum(r["cor"]), r["adic"], r["inv"], "", "", "", "", "", "",
                        "det=" + "".join(map(str, r["det"])) + " cor=" + "".join(map(str, r["cor"])), r["obs"]])
        else:
            w.writerow([r["codigo"], r["tarea"], r["modelo"], r["estrategia"], r["ejec"], r["truncada"], "", "", r["adic"], "", sum(r["es"]), r["tipos"], r["pou"], r["jus"], sum(r["amb"]), r["codigo_st"],
                        "es=" + "".join(map(str, r["es"])) + " amb=" + "".join(map(str, r["amb"])), r["obs"]])

print("\n===== CONCORDANCIA ENTRE EVALUADORES (submuestra) =====")
if not os.path.exists(F2):
    print("  [pendiente] no existe %s" % F2); sys.exit(0)
E2, falt2 = leer(F2)
if falt2:
    print("  Evaluador 2: FALTAN celdas en: " + ", ".join(sorted(falt2))); sys.exit(1)
com = sorted(set(E1) & set(E2)); print("  Respuestas calificadas por ambos: %d" % len(com))
def pares(sel):
    a, b = [], []
    for c in com:
        x, y = sel(E1[c]), sel(E2[c])
        if x is not None: a += x; b += y
    return a, b
grupos = [("Deteccion de errores de la clave (C1, C5, C6)", lambda d: d["det"] if d["tarea"] != "C2" else None),
          ("Correccion valida (C1, C5, C6)", lambda d: d["cor"] if d["tarea"] != "C2" else None),
          ("C2: senales, tipos, justificacion y codigo", lambda d: d["es"] + [d["tipos"], d["jus"], d["codigo_st"]] if d["tarea"] == "C2" else None),
          ("C2: ambiguedades de la clave", lambda d: d["amb"] if d["tarea"] == "C2" else None),
          ("TODAS las decisiones S/N", lambda d: d["det"] + d["cor"] if d["tarea"] != "C2" else d["es"] + [d["tipos"], d["jus"], d["codigo_st"]] + d["amb"])]
for nombre, sel in grupos:
    a, b = pares(sel); k, po = kappa(a, b)
    print("  %-46s n = %3d decisiones | acuerdo %5.1f %% | kappa de Cohen %.2f" % (nombre, len(a), po, k))
for nombre, campo in (("Errores inventados (conteo)", "inv"), ("Hallazgos o ambiguedades adicionales (conteo)", "adic")):
    xs = [(E1[c][campo], E2[c][campo]) for c in com if campo in E1[c] and E1[c][campo] is not None]
    print("  %-46s n = %3d respuestas | coinciden exacto %5.1f %% | diferencia absoluta media %.2f" % (nombre, len(xs), 100*sum(1 for x, y in xs if x == y)/len(xs), sum(abs(x - y) for x, y in xs)/len(xs)))
dis = [c for c in com if E1[c]["tarea"] != "C2" and E1[c]["det"] != E2[c]["det"]]
print("  Respuestas de diagnostico con alguna discrepancia en deteccion: %d de %d -> %s" % (len(dis), sum(1 for c in com if E1[c]["tarea"] != "C2"), ", ".join(dis)))
print("  Referencia habitual de kappa: < 0,40 pobre; 0,41-0,60 moderado; 0,61-0,80 sustancial; > 0,80 casi perfecto (Landis y Koch, 1977).")
