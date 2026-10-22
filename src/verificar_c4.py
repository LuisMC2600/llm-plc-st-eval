"""
Chequeo de "codigo intacto" de la tarea C4 (documentar FB_D sin tocar la logica).

Enunciado (tasks.json v1, C4): "entrega el mismo codigo con comentarios tecnicos
por bloque o por linea, sin modificar en absoluto la logica ni los identificadores".
Este instrumento decide, de forma deterministica y sin LLM como juez, si el codigo
de la respuesta es el FB_D original salvo comentarios y formato.

PROCEDIMIENTO
  1. El FB de referencia se toma del PROPIO prompt de C4 en tasks.json (no hay copia
     a mano): desde 'FUNCTION_BLOCK FB_D' hasta 'END_FUNCTION_BLOCK'.
  2. El codigo de la respuesta se obtiene con el extractor v2 (src/extraer_codigo.py,
     regla por patron) y luego se busca dentro el POU FB_D.
  3. Ambos textos se reducen a tokens: se eliminan comentarios (* ... *) -incluidos
     anidados, que CODESYS admite-, comentarios // de linea y pragmas { ... }; se
     ignora el espacio en blanco; se pasa todo a MAYUSCULAS porque ST no distingue
     mayusculas en palabras clave ni identificadores.
  4. Normalizacion declarada (no altera la semantica, se cuenta y se reporta):
     se eliminan los ';' vacios que siguen a END_IF / END_CASE / END_FOR /
     END_WHILE / END_REPEAT / END_VAR y los ';' repetidos.
  5. Se comparan las secuencias de tokens. Veredicto:
       INTACTO     -> identicas (con o sin normalizacion)
       MODIFICADO  -> cualquier diferencia; se lista el diff de tokens
       SIN_CODIGO  -> la respuesta no contiene ningun FUNCTION_BLOCK
     (si el FB aparece con otro nombre se compara igual: sale MODIFICADO por el nombre)

Uso:
  python src/verificar_c4.py <carpeta_raw> <salida.csv> [--tasks ruta/tasks.json]
     recorre <carpeta_raw>/<modelo>/C4/<estrategia>/ejec_N.st (respuestas CRUDAS)
  python src/verificar_c4.py --probar     ejecuta los dobles de validacion
"""
from __future__ import annotations

import argparse
import csv
import difflib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extraer_codigo import extraer  # noqa: E402

VERSION = "c4-v1-2026-10-01"
RE_TOKEN = re.compile(r":=|=>|<=|>=|<>|\*\*|[A-Za-z_][A-Za-z0-9_]*(?:#[A-Za-z0-9_.#]+)?|\d[\d_.]*(?:[eE][+-]?\d+)?|\S")
CIERRES = {"END_IF", "END_CASE", "END_FOR", "END_WHILE", "END_REPEAT", "END_VAR"}
RE_FB_D = re.compile(r"FUNCTION_BLOCK\s+FB_D\b.*?END_FUNCTION_BLOCK", re.S | re.I)
RE_FB_ALGUNO = re.compile(r"FUNCTION_BLOCK\s+\w+.*?END_FUNCTION_BLOCK", re.S | re.I)


def quitar_comentarios(texto: str) -> str:
    """Elimina (* *) con anidamiento, // hasta fin de linea y pragmas { }."""
    salida, i, n, prof = [], 0, len(texto), 0
    while i < n:
        dos = texto[i:i + 2]
        if dos == "(*":
            prof += 1
            i += 2
            continue
        if prof:
            if dos == "*)":
                prof -= 1
                i += 2
            else:
                i += 1
            continue
        if dos == "//":
            j = texto.find("\n", i)
            i = n if j < 0 else j
            continue
        if texto[i] == "{":
            j = texto.find("}", i)
            i = n if j < 0 else j + 1
            continue
        salida.append(texto[i])
        i += 1
    return "".join(salida)


def tokens(codigo: str):
    """Tokens en mayusculas y numero de ';' eliminados por la normalizacion."""
    crudos = [t.upper() for t in RE_TOKEN.findall(quitar_comentarios(codigo))]
    out, normalizados = [], 0
    for t in crudos:
        if t == ";" and out and (out[-1] in CIERRES or out[-1] == ";"):
            normalizados += 1
            continue
        out.append(t)
    return out, normalizados


def referencia(ruta_tasks: str) -> str:
    t = json.load(open(ruta_tasks, encoding="utf-8"))
    lista = t if isinstance(t, list) else t.get("tareas", t)
    for x in lista:
        if x["id"] == "C4":
            m = RE_FB_D.search(x["prompts"]["zero_shot"])
            if not m:
                raise SystemExit("No se encontro FB_D en el prompt de C4")
            m2 = RE_FB_D.search(x["prompts"]["few_shot"])
            if not m2 or m2.group(0) != m.group(0):
                raise SystemExit("El FB_D de zero-shot y few-shot no coincide")
            return m.group(0)
    raise SystemExit("C4 no esta en tasks.json")


def verificar(respuesta: str, ref_tokens) -> dict:
    codigo, regla, _ = extraer(respuesta)
    m = RE_FB_D.search(quitar_comentarios_conservando(codigo)) or RE_FB_ALGUNO.search(quitar_comentarios(codigo))
    if not m and re.search(r"FUNCTION_BLOCK\s+\w+", quitar_comentarios(codigo), re.I):
        # Hay cabecera de FB pero su END_FUNCTION_BLOCK quedo dentro de un comentario sin
        # cerrar (o falta): el codigo esta danado -> se compara lo que queda y sale MODIFICADO.
        m = re.search(r"FUNCTION_BLOCK\s+\w+.*", quitar_comentarios(codigo), re.S | re.I)
    if not m:
        return {"veredicto": "SIN_CODIGO", "regla_extraccion": regla, "n_diferencias": "",
                "normalizados": "", "diff": ""}
    toks, norm = tokens(codigo_fb_d(codigo))
    if toks == ref_tokens:
        return {"veredicto": "INTACTO", "regla_extraccion": regla, "n_diferencias": 0,
                "normalizados": norm, "diff": ""}
    ops = [op for op in difflib.SequenceMatcher(a=ref_tokens, b=toks, autojunk=False).get_opcodes() if op[0] != "equal"]
    diff = "; ".join("%s ref[%s] -> resp[%s]" % (tag, " ".join(ref_tokens[i1:i2]), " ".join(toks[j1:j2]))
                     for tag, i1, i2, j1, j2 in ops)
    return {"veredicto": "MODIFICADO", "regla_extraccion": regla, "n_diferencias": len(ops),
            "normalizados": norm, "diff": diff[:500]}


def quitar_comentarios_conservando(codigo: str) -> str:
    """Para localizar FB_D sin que un comentario que diga 'FUNCTION_BLOCK FB_D' confunda."""
    return quitar_comentarios(codigo)


def codigo_fb_d(codigo: str) -> str:
    """Texto desde 'FUNCTION_BLOCK FB_D' hasta su END_FUNCTION_BLOCK, buscado sin comentarios
    pero devuelto en tokens equivalentes: como los comentarios se descartan de todos modos,
    basta con recortar el texto ya sin comentarios."""
    sin = quitar_comentarios(codigo)
    m = (RE_FB_D.search(sin) or RE_FB_ALGUNO.search(sin)  # FB renombrado: se compara igual y sale MODIFICADO
         or re.search(r"FUNCTION_BLOCK\s+\w+.*", sin, re.S | re.I))  # FB truncado por comentario sin cerrar
    return m.group(0) if m else ""


def procesar(carpeta_raw: str, salida: str, ruta_tasks: str) -> None:
    ref_tokens, _ = tokens(referencia(ruta_tasks))
    filas = []
    for modelo in sorted(os.listdir(carpeta_raw)):
        base = os.path.join(carpeta_raw, modelo, "C4")
        if not os.path.isdir(base):
            continue
        for estr in sorted(os.listdir(base)):
            for f in sorted(os.listdir(os.path.join(base, estr))):
                if f.endswith(".st"):
                    texto = open(os.path.join(base, estr, f), encoding="utf-8", errors="replace").read()
                    r = verificar(texto, ref_tokens)
                    r.update({"modelo": modelo, "estrategia": estr, "ejec": f[:-3], "version": VERSION})
                    filas.append(r)
    campos = ["modelo", "estrategia", "ejec", "veredicto", "n_diferencias", "normalizados",
              "regla_extraccion", "diff", "version"]
    with open(salida, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=campos)
        w.writeheader()
        w.writerows(filas)
    from collections import Counter
    print("Respuestas C4: %d -> %s" % (len(filas), salida))
    print("Veredictos:", dict(Counter(r["veredicto"] for r in filas)))


# ------------------------------------------------------------------ dobles de validacion
def dobles(ref: str):
    """(nombre, texto de respuesta, veredicto esperado). NO son corpus."""
    lineas = ref.splitlines()
    comentado = "\n".join(
        l + ("  // " + "comentario de linea" if l.strip().endswith(";") else "") for l in lineas)
    comentado = comentado.replace("fDem(CLK := demanda);",
                                  "(* Deteccion de flanco (* anidado *) de la demanda *)\nfDem(CLK := demanda);")
    envolver = lambda c: "El bloque alterna dos bombas en duplex...\n\n```iecst\n%s\n```\n\nNotas finales." % c
    return [
        ("OriginalSinCambios", envolver(ref), "INTACTO"),
        ("ComentadoLineaYBloque", envolver(comentado), "INTACTO"),
        ("ComentarioConPalabrasClave", envolver(ref.replace(
            "IF demanda THEN", "(* IF falla1 THEN bomba1 := TRUE; END_IF -- ejemplo, no es codigo *)\nIF demanda THEN")), "INTACTO"),
        ("ComentarioConDobleBarraDentro", envolver(ref.replace(
            "turno : BOOL;", "turno : BOOL; (* rol: // principal *)")), "INTACTO"),
        ("Reindentado", envolver("\n".join(l.strip() for l in lineas)), "INTACTO"),
        ("MinusculasEnPalabrasClave", envolver(ref.replace("END_IF", "end_if").replace("THEN", "then")), "INTACTO"),
        ("PuntoYComaTrasEND_IF", envolver(ref.replace("END_IF", "END_IF;")), "INTACTO"),
        ("PragmaAtributo", envolver("{attribute 'qualified_only'}\n" + ref), "INTACTO"),
        ("SinFence", "Descripcion del bloque.\n\n" + ref, "INTACTO"),
        ("IdentificadorRenombrado", envolver(ref.replace("turno", "turnoB1")), "MODIFICADO"),
        ("FBRenombrado", envolver(ref.replace("FB_D", "FB_Duplex")), "MODIFICADO"),
        ("OperadorCambiado", envolver(ref.replace("falla1 AND NOT falla2", "falla1 OR NOT falla2")), "MODIFICADO"),
        ("NOTEliminado", envolver(ref.replace("turno := NOT turno;", "turno := turno;")), "MODIFICADO"),
        ("LineaEliminada", envolver(ref.replace("        almFalla := falla1;\n", "")), "MODIFICADO"),
        ("SentenciasReordenadas", envolver(ref.replace(
            "        bomba1 := NOT falla1;\n        bomba2 := falla1 AND NOT falla2;",
            "        bomba2 := falla1 AND NOT falla2;\n        bomba1 := NOT falla1;")), "MODIFICADO"),
        ("InicializacionAnadida", envolver(ref.replace("turno : BOOL;", "turno : BOOL := FALSE;")), "MODIFICADO"),
        ("ELSIFenLugarDeELSE", envolver(ref.replace("    ELSE\n        bomba2", "    ELSIF NOT turno THEN\n        bomba2")), "MODIFICADO"),
        ("CodigoComentadoFuera", envolver(ref.replace("        almFalla := falla2;", "        (* almFalla := falla2; *)")), "MODIFICADO"),
        ("ComentarioSinCerrarTragaCodigo", envolver(ref.replace(
            "ELSE\n    bomba1 := FALSE;", "ELSE (* rama sin demanda\n    bomba1 := FALSE;")), "MODIFICADO"),
        ("SinCodigo", "Solo un parrafo de descripcion, sin codigo.", "SIN_CODIGO"),
    ]


def probar(ruta_tasks: str) -> bool:
    ref = referencia(ruta_tasks)
    ref_tokens, _ = tokens(ref)
    ok_total = True
    print("VALIDACION DE verificar_c4 (%s) -- %d tokens de referencia" % (VERSION, len(ref_tokens)))
    for nombre, texto, esperado in dobles(ref):
        r = verificar(texto, ref_tokens)
        ok = r["veredicto"] == esperado
        ok_total &= ok
        print("%-32s %-11s esperado %-11s %s  %s" % (nombre, r["veredicto"], esperado, "ok" if ok else "NO",
                                                    (r["diff"] or "")[:70]))
    print("Discrimina:", "SI" if ok_total else "NO")
    return ok_total


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Chequeo de codigo intacto de C4.")
    ap.add_argument("carpeta_raw", nargs="?")
    ap.add_argument("salida", nargs="?")
    ap.add_argument("--tasks", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "tasks.json"))
    ap.add_argument("--probar", action="store_true")
    a = ap.parse_args()
    if a.probar:
        sys.exit(0 if probar(a.tasks) else 1)
    if not (a.carpeta_raw and a.salida):
        ap.error("indica carpeta_raw y salida, o --probar")
    procesar(a.carpeta_raw, a.salida, a.tasks)
