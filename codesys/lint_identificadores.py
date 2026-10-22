"""Revisa que ningun doble ni harness declare como variable una palabra reservada
IEC 61131-3 / CODESYS (p. ej. DT, TOD, DATE). Leccion del 30-09 y 01-10-2026.
"d" y "t" como identificadores SI compilan en CODESYS (verificado con A4 y B2)."""
import glob, re, sys
RESERVADAS = {"DT", "TOD", "DATE", "TIME", "LTIME", "ON", "AT", "BY", "DO", "IF", "OF", "OR", "TO", "END",
              "MOD", "NOT", "XOR", "AND", "VAR", "TYPE", "STRING", "WSTRING", "REAL", "INT", "BOOL",
              "R_EDGE", "F_EDGE", "STEP", "ACTION", "TASK", "RETAIN", "CONSTANT", "METHOD",
              "INTERFACE", "PROPERTY", "THIS", "SUPER", "TRUE", "FALSE"}
mal = []
for f in sorted(glob.glob("dobles/*/*.st") + glob.glob("PRG_Test_*.st")):
    for n, linea in enumerate(open(f, encoding="utf-8", errors="replace"), 1):
        m = re.match(r"\s*([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:\s*[A-Za-z]", linea)
        if m:
            for nombre in re.split(r"\s*,\s*", m.group(1)):
                if nombre.upper() in RESERVADAS:
                    mal.append("%s:%d  %s" % (f, n, nombre))
print("\n".join(mal) if mal else "Sin identificadores reservados en %d archivos" % len(glob.glob("dobles/*/*.st") + glob.glob("PRG_Test_*.st")))
sys.exit(1 if mal else 0)
