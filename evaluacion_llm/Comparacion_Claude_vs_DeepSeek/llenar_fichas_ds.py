"""Llena copias de las fichas del Evaluador 1 con la evaluación IA NO OFICIAL.
Valida antes de escribir: mismos códigos que la ficha, sin faltantes, rangos y valores fijados.
"""
import json, sys, openpyxl
from openpyxl.styles import PatternFill, Font

BASE = "/mnt/user-data/outputs"
SAL = "/home/claude/ia_eval/salida_ds"
OUT = "/home/claude/ia_eval/fichas_ia"
ROJO = PatternFill("solid", fgColor="F4CCCC")
errores = []

def banner(wb, texto):
    for ws in wb.worksheets:
        ws["A1"] = f"[{texto}] " + str(ws["A1"].value or "")
        ws["A1"].font = Font(bold=True, color="C00000", size=12)
        ws["A1"].fill = ROJO

def filas(ws):
    r = 6
    while ws.cell(r, 1).value:
        yield r, ws.cell(r, 1).value
        r += 1

SN = {"S", "N"}

# ---------- Diagnóstico ----------
wb = openpyxl.load_workbook(f"{BASE}/evaluacion_manual/Ficha_Evaluador1.xlsx")
for t in ["C1", "C5", "C6"]:
    ws = wb[t]
    d = {x["codigo"]: x for x in json.load(open(f"{SAL}/diag_{t}.json"))}
    cods = [c for _, c in filas(ws)]
    if set(cods) != set(d) or len(d) != 24:
        errores.append(f"{t}: códigos no coinciden ({len(cods)} ficha / {len(d)} IA)")
    for r, c in filas(ws):
        x = d[c]
        for i in range(4):
            det, cor = x["det"][i], x["cor"][i]
            if det not in SN: errores.append(f"{c} det{i+1}={det}")
            if det == "S" and cor not in SN: errores.append(f"{c} cor{i+1}={cor}")
            ws.cell(r, 2 + 2 * i, det)
            ws.cell(r, 3 + 2 * i, cor if det == "S" else None)
        ws.cell(r, 10, int(x["adic"])); ws.cell(r, 11, int(x["inv"]))
        ws.cell(r, 12, x.get("obs", ""))
ws = wb["C2"]
d = {x["codigo"]: x for x in json.load(open(f"{SAL}/diag_C2.json"))}
if set(c for _, c in filas(ws)) != set(d) or len(d) != 24:
    errores.append("C2: códigos no coinciden")
for r, c in filas(ws):
    x = d[c]
    vals = x["es"] + [x["tipos"], x["pou"], x["jus"]] + x["amb"] + [int(x["adic"]), x["codigo_st"], x.get("obs", "")]
    for j, v in enumerate(vals):
        ws.cell(r, 2 + j, v)
    for v in x["es"] + [x["tipos"], x["jus"], x["codigo_st"]] + x["amb"]:
        if v not in SN: errores.append(f"{c}: valor S/N inválido {v}")
banner(wb, "EVALUADOR LLM 2 — DeepSeek deepseek-v4-pro — pendiente de decisión")
wb.save(f"{OUT}/Ficha_DeepSeek_Diagnostico.xlsx")

# ---------- Rúbrica ----------
wb = openpyxl.load_workbook(f"{BASE}/evaluacion_rubrica/Ficha_Rubrica_Evaluador1.xlsx")
n = 0
for ws in wb.worksheets[2:]:
    t = ws.title
    d = {x["codigo"]: x for x in json.load(open(f"{SAL}/rub_{t}.json"))}
    if set(c for _, c in filas(ws)) != set(d) or len(d) != 24:
        errores.append(f"{t}: códigos no coinciden")
    for r, c in filas(ws):
        x = d[c]
        for col, k in zip(range(3, 8), ["funcional", "iec", "coherencia", "claridad", "mantenibilidad"]):
            v = int(x[k])
            if not 0 <= v <= 3: errores.append(f"{c} {k}={v}")
            pre = ws.cell(r, col).value
            if pre is not None and pre != v:
                errores.append(f"{c} {k}: fijado {pre} vs IA {v}")
            ws.cell(r, col, v)
        res = str(ws.cell(r, 2).value)
        if res.startswith("No compila") and int(x["iec"]) != 0: errores.append(f"{c}: no compila e iec≠0")
        if res.startswith("No compila") and int(x["funcional"]) != 0: errores.append(f"{c}: no compila y func≠0")
        if not res.startswith("No compila") and int(x["iec"]) == 0: errores.append(f"{c}: compila e iec=0")
        if "Pasa" in res and "Falla" not in res and int(x["funcional"]) != 3: errores.append(f"{c}: pasa y func≠3")
        if "Falla" in res and int(x["funcional"]) == 3: errores.append(f"{c}: falla y func=3")
        for col, k in zip(range(9, 13), ["just_func_iec", "just_coherencia", "just_claridad", "just_mantenibilidad"]):
            ws.cell(r, col, x.get(k, ""))
        n += 1
banner(wb, "EVALUADOR LLM 2 — DeepSeek deepseek-v4-pro — pendiente de decisión")
wb.save(f"{OUT}/Ficha_DeepSeek_Rubrica.xlsx")

print("respuestas rúbrica:", n)
print("ERRORES:", len(errores)); print("\n".join(errores[:60]))
