# -*- coding: utf-8 -*-
"""
Compilacion por lotes en CODESYS — ScriptEngine (IronPython).

Automatiza la ETAPA 1 de la verificacion: importa cada respuesta .st como POU,
compila y registra el resultado en un CSV. Sustituye el trabajo manual de
abrir, pegar y pulsar F11 cientos de veces.

EJECUCION (linea de comandos de Windows, CODESYS cerrado):

  "C:\\Program Files\\CODESYS 3.5.x.x\\CODESYS\\Common\\CODESYS.exe" ^
      --runscript="<ruta>\\compilar_lote.py" ^
      --scriptargs:"<carpeta_codigo_limpio> <csv_salida>" ^
      --noUI

IMPORTANTE — ADAPTACION REQUERIDA:
Los nombres exactos de la API del ScriptEngine varian entre versiones de
CODESYS. Las llamadas marcadas con [API] deben verificarse contra la
referencia de TU version antes de la corrida masiva:
  https://content.helpme-codesys.com/en/ScriptingEngine/index.html
Procedimiento recomendado: probar primero con UNA carpeta de 2-3 archivos,
ajustar lo que falle, y solo entonces lanzar el lote completo.

NOTA METODOLOGICA: este script NO modifica el codigo evaluado. Solo lo
importa, lo compila y anota el resultado.
"""

import os
import sys
import csv
import re

# --- Parametros -------------------------------------------------------------
args = (system.get_script_args() if hasattr(system, "get_script_args") else sys.argv[1:])  # [API]
CARPETA = args[0] if len(args) > 0 else r"..\repositorio_piloto_limpio"
SALIDA = args[1] if len(args) > 1 else r"..\resultados_compilacion.csv"

# Tipo de POU esperado por tarea (del banco de pruebas).
# B7 es el unico PROGRAM del subconjunto piloto; el resto son FUNCTION_BLOCK.
POU_ESPERADO = {
    "B1": "FunctionBlock", "B2": "FunctionBlock", "B3": "FunctionBlock",
    "B4": "FunctionBlock", "B5": "FunctionBlock", "B6": "FunctionBlock",
    "B7": "Program",       "B8": "FunctionBlock",
    "I1": "FunctionBlock", "I2": "FunctionBlock", "I3": "FunctionBlock",
    "I4": "FunctionBlock", "I5": "FunctionBlock", "I6": "FunctionBlock",
    "I7": "FunctionBlock", "I8": "FunctionBlock",
}

RE_CABECERA = re.compile(
    r"^\s*(FUNCTION_BLOCK|PROGRAM|FUNCTION)\s+(\w+)", re.IGNORECASE | re.MULTILINE)
RE_FIN_DECL = re.compile(r"END_VAR", re.IGNORECASE)


def partir_codigo(texto):
    """Separa declaracion e implementacion como espera el editor de CODESYS.

    El editor no incluye la linea END_FUNCTION_BLOCK: se descarta si existe.
    Devuelve (declaracion, implementacion, nombre_pou) o None si no hay cabecera.
    """
    m = RE_CABECERA.search(texto)
    if not m:
        return None
    nombre = m.group(2)
    # La declaracion abarca hasta el ULTIMO END_VAR.
    fines = list(RE_FIN_DECL.finditer(texto))
    if not fines:
        return None
    corte = fines[-1].end()
    decl = texto[:corte]
    impl = texto[corte:]
    # Retirar el cierre del POU, que el editor gestiona por su cuenta.
    impl = re.sub(r"END_(FUNCTION_BLOCK|PROGRAM|FUNCTION)\s*$", "", impl,
                  flags=re.IGNORECASE).strip()
    return decl, impl, nombre


def listar_archivos(raiz):
    """Devuelve (ruta, modelo, tarea, estrategia, ejecucion) por cada .st."""
    salida = []
    for dirpath, _, files in os.walk(raiz):
        for f in files:
            if not f.lower().endswith(".st"):
                continue
            ruta = os.path.join(dirpath, f)
            partes = os.path.normpath(ruta).split(os.sep)
            # .../<modelo>/<tarea>/<estrategia>/ejec_N.st
            try:
                modelo, tarea, estrategia = partes[-4], partes[-3], partes[-2]
                ejec = os.path.splitext(f)[0].replace("ejec_", "")
            except IndexError:
                modelo = tarea = estrategia = ejec = "?"
            salida.append((ruta, modelo, tarea, estrategia, ejec))
    return sorted(salida)


# --- Proceso principal ------------------------------------------------------
archivos = listar_archivos(CARPETA)
system.write_message(Severity.Information,
                     "Archivos a compilar: %d" % len(archivos))          # [API]

filas = []
for i, (ruta, modelo, tarea, estrategia, ejec) in enumerate(archivos, 1):
    with open(ruta, "r") as fh:
        texto = fh.read().decode("utf-8", "ignore") if hasattr(fh.read(), "decode") else None
    # IronPython 2.7: lectura simple y decodificacion explicita
    with open(ruta, "rb") as fh:
        texto = fh.read().decode("utf-8", "ignore")

    fila = {
        "archivo": ruta, "modelo": modelo, "tarea": tarea,
        "estrategia": estrategia, "ejecucion": ejec,
        "compila": 0, "n_errores": "", "n_advertencias": "",
        "primer_error": "", "nota": "",
    }

    partido = partir_codigo(texto)
    if partido is None:
        # Sin cabecera o sin bloque de declaracion: no se puede importar como POU.
        fila["nota"] = "sin cabecera de POU o sin END_VAR; no importable"
        fila["primer_error"] = "estructura de POU ausente"
        filas.append(fila)
        continue

    decl, impl, nombre = partido
    tipo = POU_ESPERADO.get(tarea, "FunctionBlock")

    proyecto = None
    try:
        # Proyecto temporal limpio por cada respuesta: evita contaminacion
        # entre evaluaciones (nombres repetidos, estado residual).
        proyecto = projects.create(r"%s\tmp_%s.project" %
                                   (os.environ.get("TEMP", "."), i))       # [API]

        app = proyecto.active_application                                   # [API]
        pou = app.create_pou(nombre, PouType.__getattribute__(PouType, tipo))  # [API]
        pou.textual_declaration.replace(decl)                               # [API]
        pou.textual_implementation.replace(impl)                            # [API]

        proyecto.build()                                                    # [API]

        # Recuento de errores tras la compilacion.
        # [API] Verificar el mecanismo en tu version: puede ser
        # system.get_message_count(Severity.Error), proyecto.get_build_messages(),
        # o la lectura del message store. Ajustar aqui.
        n_err = system.get_message_count(Severity.Error)                    # [API]
        n_adv = system.get_message_count(Severity.Warning)                  # [API]

        fila["n_errores"] = n_err
        fila["n_advertencias"] = n_adv
        fila["compila"] = 1 if n_err == 0 else 0
        if n_err > 0:
            msgs = system.get_messages(Severity.Error)                      # [API]
            fila["primer_error"] = (str(msgs[0]) if msgs else "")[:300]

    except Exception as e:
        fila["nota"] = "excepcion del script: %s" % str(e)[:200]
    finally:
        if proyecto is not None:
            try:
                proyecto.close()                                            # [API]
            except Exception:
                pass

    filas.append(fila)
    if i % 10 == 0:
        system.write_message(Severity.Information, "  procesados %d/%d" %
                             (i, len(archivos)))

# --- Escritura del resultado ------------------------------------------------
campos = ["archivo", "modelo", "tarea", "estrategia", "ejecucion",
          "compila", "n_errores", "n_advertencias", "primer_error", "nota"]
with open(SALIDA, "wb") as fh:
    w = csv.DictWriter(fh, fieldnames=campos)
    w.writeheader()
    for f in filas:
        w.writerow(dict((k, unicode(v).encode("utf-8")) for k, v in f.items()))

ok = sum(1 for f in filas if f["compila"] == 1)
system.write_message(Severity.Information,
                     "TERMINADO. Compilan %d de %d. Resultado: %s" %
                     (ok, len(filas), SALIDA))
