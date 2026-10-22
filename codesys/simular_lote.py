# -*- coding: utf-8 -*-
"""
Simulacion por lotes en CODESYS -- ScriptEngine (IronPython). CAPA 2 de la
verificacion (Guia_Automatizacion_CODESYS.docx, seccion 4): automatiza lo que
compilar_lote.py NO hace -- vincular cada respuesta con el harness de su
tarea, fijar el ciclo de la MainTask, entrar en simulacion, ejecutar el
banco hasta que termine, leer 'veredicto' y 'resultado[]', y registrar todo
en un CSV.

ESTADO: PROPUESTA SIN PROBAR. Igual que compilar_lote.py, no hay CODESYS
instalado en el entorno donde se escribio este script. Cada llamada se marca:

  [API-OK]  verificado contra la documentacion oficial del ScriptingEngine
            (content.helpme-codesys.com/en/ScriptingEngine/), pero SIN
            probar contra tu version instalada.
  [API]     no encontrado en la documentacion consultada; nombre y firma son
            la mejor hipotesis a partir del resto de la API y de patrones
            usuales de CODESYS scripting. Es el mismo nivel de certeza que
            ya tenian TODAS las llamadas de compilar_lote.py.

Procedimiento recomendado (igual que Etapa 3 de PROMPTS_FASE_CODESYS.md):
probar primero con una carpeta de 2-3 archivos y UN solo ciclo de tarea,
corregir lo que falle, y solo entonces lanzar el lote completo en los dos
ciclos (enmienda 3: 4 ms y 10 ms).

REQUISITO PREVIO (una sola vez, a mano en la GUI de CODESYS): preparar
'codesys/Plantilla_Simulacion.project' -- Standard Project, device
"CODESYS Control Win V3 x64", con la MainTask ya creada (no hace falta
fijar su ciclo: este script lo hace por iteracion), y SIN ningun POU de
FB ni de harness (el script los agrega y los quita en cada iteracion).

MECANISMO PARA EVITAR CONTAMINACION ENTRE RESPUESTAS: el script ABRE esa
plantilla, la modifica en memoria, simula, y la CIERRA SIN GUARDAR. Nunca
llames a proyecto.save() sobre la plantilla o dejara de estar limpia para
la siguiente iteracion -- es la razon por la que no hace falta borrar los
POUs de la iteracion anterior antes de crear los nuevos.

EJECUCION (linea de comandos de Windows, CODESYS cerrado):

  "C:\\Program Files\\CODESYS 3.5.x.x\\CODESYS\\Common\\CODESYS.exe" ^
      --runscript="<ruta>\\simular_lote.py" ^
      --scriptargs:"<carpeta_codigo> <plantilla.project> <carpeta_harness> <csv_salida>" ^
      --noUI

NOTA METODOLOGICA: igual que compilar_lote.py, este script NO modifica el
codigo evaluado. Solo lo importa, lo vincula con el harness ya aprobado, lo
compila, lo simula y anota el resultado.
"""

import os
import sys
import csv
import re
import time

# --- Parametros -------------------------------------------------------------
args = (system.get_script_args() if hasattr(system, "get_script_args") else sys.argv[1:])  # [API] (igual que compilar_lote.py)
CARPETA_CODIGO = args[0] if len(args) > 0 else r"..\data\codesys_piloto\reconstruidos"
PLANTILLA = args[1] if len(args) > 1 else r".\Plantilla_Simulacion.project"
CARPETA_HARNESS = args[2] if len(args) > 2 else r"."
SALIDA = args[3] if len(args) > 3 else r"..\data\codesys_piloto\resultados_simulacion.csv"

# Ciclos de MainTask a probar (enmienda 3 de ENMIENDAS_HARNESSES.md): el
# lote completo se corre una vez por cada valor de esta lista.
CICLOS_MS = [10, 4]

# Nombre del harness y del bloque bajo prueba por tarea, y cuantos indices
# tiene su arreglo 'resultado' (ULTIMO_PASO + 1), tomado de cada .st real.
HARNESS_POR_TAREA = {
    "B1": ("PRG_Test_B1", "FB_Motor", 7),
    "B2": ("PRG_Test_B2", "FB_Valvula", 6),
    "B3": ("PRG_Test_B3", "FB_Contador", 7),
    "B4": ("PRG_Test_B4", "FB_Giro", 10),
    "B5": ("PRG_Test_B5", "FB_Ventilador", 9),
    "B6": ("PRG_Test_B6", "FB_Baliza", 3),
    "I1": ("PRG_Test_I1", "FB_Semaforo", 9),
    "I2": ("PRG_Test_I2", "FB_Llenado", 12),
    "I3": ("PRG_Test_I3", "FB_Alarmas", 10),
    "I4": ("PRG_Test_I4", "FB_EstrellaTriangulo", 6),
    "I5": ("PRG_Test_I5", "FB_Clasificadora", 7),
    "I6": ("PRG_Test_I6", "FB_Temperatura", 8),
}

# Duracion medida de cada secuencia (VERIFICACION_CODESYS.md, seccion 1) mas
# un margen del 50% y un piso de 5 s, como tiempo maximo de espera por
# respuesta antes de registrar "sin veredicto" y seguir con la siguiente.
# B3 usa el estimado (~2.1 s) hasta que se mida en CODESYS real.
DURACION_S = {
    "B1": 1.6, "B2": 12.9, "B3": 2.1, "B4": 1.5, "B5": 71.2, "B6": 9.7,
    "I1": 70.6, "I2": 62.6, "I3": 1.5, "I4": 9.2, "I5": 4.0, "I6": 0.8,
}


def timeout_por_tarea(tarea):
    return max(5.0, DURACION_S.get(tarea, 30.0) * 1.5)


RE_POU_HEADER = re.compile(
    r"^\s*(FUNCTION_BLOCK|PROGRAM|FUNCTION)\s+(\w+)", re.IGNORECASE | re.MULTILINE)
RE_FIN_DECL = re.compile(r"END_VAR", re.IGNORECASE)


def partir_codigo(texto):
    """Identico a compilar_lote.py: separa declaracion e implementacion como
    espera el editor de CODESYS, y descarta la linea de cierre del POU."""
    m = RE_POU_HEADER.search(texto)
    if not m:
        return None
    nombre = m.group(2)
    fines = list(RE_FIN_DECL.finditer(texto))
    if not fines:
        return None
    corte = fines[-1].end()
    decl = texto[:corte]
    impl = texto[corte:]
    impl = re.sub(r"END_(FUNCTION_BLOCK|PROGRAM|FUNCTION)\s*$", "", impl,
                  flags=re.IGNORECASE).strip()
    return decl, impl, nombre


def leer_archivo(ruta):
    with open(ruta, "rb") as fh:
        return fh.read().decode("utf-8", "ignore")


def listar_archivos(raiz):
    """Igual que compilar_lote.py: (ruta, modelo, tarea, estrategia, ejecucion)
    por cada .st, inferido de <modelo>/<tarea>/<estrategia>/ejec_N.st."""
    salida = []
    for dirpath, _, files in os.walk(raiz):
        for f in files:
            if not f.lower().endswith(".st"):
                continue
            ruta = os.path.join(dirpath, f)
            partes = os.path.normpath(ruta).split(os.sep)
            try:
                modelo, tarea, estrategia = partes[-4], partes[-3], partes[-2]
                ejec = os.path.splitext(f)[0].replace("ejec_", "")
            except IndexError:
                modelo = tarea = estrategia = ejec = "?"
            salida.append((ruta, modelo, tarea, estrategia, ejec))
    return sorted(salida)


def simular_respuesta(ruta_fb, tarea, ciclo_ms):
    """Devuelve un dict con el resultado de compilar y simular UNA respuesta
    contra el harness de su tarea, a un ciclo de MainTask dado.

    Abre la plantilla, la modifica, simula y la cierra SIN GUARDAR -- ver
    docstring del modulo. No usa PLANTILLA como variable global mutable de
    ningun otro modo.
    """
    nombre_harness, nombre_fb_esperado, n_pasos = HARNESS_POR_TAREA[tarea]

    fila = {
        "compila": 0, "n_errores": "", "primer_error": "",
        "veredicto": "", "pasos_fallidos": "", "nota": "",
    }

    texto_fb = leer_archivo(ruta_fb)
    partido_fb = partir_codigo(texto_fb)
    if partido_fb is None:
        fila["nota"] = "sin cabecera de POU o sin END_VAR; no importable"
        return fila
    decl_fb, impl_fb, nombre_fb_real = partido_fb

    ruta_harness = os.path.join(CARPETA_HARNESS, nombre_harness + ".st")
    texto_harness = leer_archivo(ruta_harness)
    partido_harness = partir_codigo(texto_harness)
    decl_harness, impl_harness, _ = partido_harness

    proyecto = None
    online_app = None
    try:
        proyecto = projects.open(PLANTILLA)                                  # [API]
        app = proyecto.active_application                                    # [API] (igual que compilar_lote.py)

        # --- 1. POU del bloque bajo prueba -----------------------------------
        # nombre_fb_real es el nombre que el propio modelo puso a su FB; si no
        # coincide con el que el harness espera (nombre_fb_esperado), el build
        # va a fallar con "identifier not found" -- eso es un resultado, no un
        # error del script (ya se detecto por analisis estatico en el mapa de
        # compatibilidad de VERIFICACION_CODESYS.md).
        pou_fb = app.create_pou(nombre_fb_real, PouType.FunctionBlock,       # [API-OK] create_pou existe en
                                 ScriptImplementationLanguage.st)             # ScriptIecLanguageObjectContainer;
                                                                               # firma exacta (orden/nombres de
                                                                               # parametros) sin confirmar -- [API]
        pou_fb.textual_declaration.replace(decl_fb)                          # [API-OK] ScriptObjectWithTextualDeclaration
        pou_fb.textual_implementation.replace(impl_fb)                       # [API-OK] ScriptObjectWithTextualImplementation

        # --- 2. POU del harness (ya aprobado, no se modifica su contenido) ---
        pou_harness = app.create_pou(nombre_harness, PouType.Program,        # [API-OK]/[API] igual que arriba
                                      ScriptImplementationLanguage.st)
        pou_harness.textual_declaration.replace(decl_harness)                # [API-OK]
        pou_harness.textual_implementation.replace(impl_harness)             # [API-OK]

        # --- 3. Vincular el harness a la MainTask y fijar el ciclo -----------
        task_config = app.find("Task Configuration", True)[0]                # [API] find(nombre, recursivo) es un
        main_task = task_config.find("MainTask", True)[0]                    # patron habitual de CODESYS scripting,
                                                                               # no confirmado en la documentacion
                                                                               # consultada -- VERIFICAR
        main_task.interval = ciclo_ms                                        # [API-OK] ScriptTaskObject.interval existe
        main_task.interval_unit = TimeUnit.ms                                # [API] interval_unit existe (confirmado);
                                                                               # el nombre exacto del enum (TimeUnit.ms
                                                                               # vs otro) NO esta confirmado -- VERIFICAR
        main_task.pous.add(pou_harness)                                      # [API] ScriptTaskObject.pous es una
                                                                               # ScriptPouObjectCollection con add()
                                                                               # (confirmado que existe el metodo;
                                                                               # el argumento -- objeto POU vs nombre/
                                                                               # GUID -- no esta confirmado)

        # --- 4. Compilar ------------------------------------------------------
        proyecto.build()                                                     # [API] (igual que compilar_lote.py)
        errores = system.get_messages(Severity.Error)                        # [API-OK] System.get_messages existe
        fila["n_errores"] = len(errores)
        fila["compila"] = 1 if not errores else 0
        if errores:
            fila["primer_error"] = (str(errores[0]) if errores else "")[:300]
            return fila  # no tiene sentido simular algo que no compilo

        # --- 5. Simulacion ------------------------------------------------
        device = app.find("Device", True)[0]                                 # [API] mismo patron que Task
                                                                               # Configuration arriba; el nombre real
                                                                               # del device es el que tenga la
                                                                               # plantilla ("Device" por defecto en un
                                                                               # Standard Project) -- VERIFICAR
        device.set_simulation_mode(True)                                     # [API-OK] ScriptDeviceObject.set_simulation_mode
        online_app = online.create_online_application(app)                   # [API-OK] ScriptOnline.create_online_application
        online_app.login(OnlineChangeOption.Try, "")                         # [API-OK] .login existe; firma exacta
                                                                               # (parametros de OnlineChangeOption y
                                                                               # credenciales) no confirmada -- VERIFICAR
        online_app.reset(ResetOption.Cold)                                   # [API-OK] .reset existe;
                                                                               # ResetOption.Cold confirmado
        online_app.start()                                                   # [API-OK] ScriptOnlineApplication.start

        # --- 6. Esperar a que termine (o timeout) --------------------------
        expr_veredicto = "%s.veredicto" % nombre_harness                     # [API] formato exacto de la cadena de
                                                                               # expresion que espera read_value/
                                                                               # read_values -- VERIFICAR (puede
                                                                               # necesitar el path completo de la
                                                                               # instancia, p. ej.
                                                                               # "Application.PRG_Test_B1.veredicto")
        t0 = time.time()
        veredicto = 0
        limite = timeout_por_tarea(tarea)
        while veredicto == 0:
            veredicto = int(online_app.read_value(expr_veredicto))           # [API-OK] .read_value existe; tipo de
                                                                               # retorno (str/objeto) no confirmado,
                                                                               # puede necesitar conversion distinta
            if veredicto != 0:
                break
            if time.time() - t0 > limite:
                fila["nota"] = "sin veredicto tras %.1f s (timeout)" % limite
                break
            system.delay(100)                                                # [API-OK] System.delay existe

        fila["veredicto"] = veredicto

        # --- 7. Leer el detalle de pasos fallidos --------------------------
        expr_resultado = ["%s.resultado[%d]" % (nombre_harness, i)           # [API] mismo formato que expr_veredicto;
                           for i in range(n_pasos)]                          # confirmar si read_values acepta una
                                                                               # lista de expresiones o si hay que
                                                                               # leerlas una a una con read_value
        resultado = online_app.read_values(expr_resultado)                   # [API-OK] .read_values existe
        fallidos = [i for i, v in enumerate(resultado) if int(v) != 1]
        fila["pasos_fallidos"] = ",".join(str(i) for i in fallidos)

    except Exception as e:
        fila["nota"] = (fila["nota"] + "; " if fila["nota"] else "") + \
                        "excepcion del script: %s" % str(e)[:200]
    finally:
        if online_app is not None:
            try:
                online_app.stop()                                            # [API-OK]
                online_app.logout()                                          # [API-OK]
            except Exception:
                pass
        if proyecto is not None:
            try:
                proyecto.close()                                             # [API] (igual que compilar_lote.py) --
                                                                               # NO llamar a proyecto.save() antes de
                                                                               # esto, o la plantilla queda sucia
            except Exception:
                pass

    return fila


# --- Proceso principal --------------------------------------------------
archivos = listar_archivos(CARPETA_CODIGO)
system.write_message(Severity.Information,                                  # [API] (igual que compilar_lote.py)
                      "Archivos a simular: %d, en %d ciclo(s) de tarea (%s ms)" %
                      (len(archivos), len(CICLOS_MS), ", ".join(str(c) for c in CICLOS_MS)))

filas = []
total = len(archivos) * len(CICLOS_MS)
i = 0
for ciclo_ms in CICLOS_MS:
    for ruta, modelo, tarea, estrategia, ejec in archivos:
        i += 1
        fila_base = {
            "archivo": ruta, "modelo": modelo, "tarea": tarea,
            "estrategia": estrategia, "ejecucion": ejec, "ciclo_ms": ciclo_ms,
        }

        if tarea not in HARNESS_POR_TAREA:
            fila_base.update({"compila": "", "n_errores": "", "primer_error": "",
                               "veredicto": "", "pasos_fallidos": "",
                               "nota": "tarea sin harness (ver seccion 5 de VERIFICACION_CODESYS.md)"})
            filas.append(fila_base)
            continue

        resultado_fila = simular_respuesta(ruta, tarea, ciclo_ms)
        fila_base.update(resultado_fila)
        filas.append(fila_base)

        if i % 5 == 0:
            system.write_message(Severity.Information, "  procesados %d/%d" % (i, total))  # [API]

# --- Escritura del resultado ----------------------------------------------
campos = ["archivo", "modelo", "tarea", "estrategia", "ejecucion", "ciclo_ms",
          "compila", "n_errores", "primer_error", "veredicto",
          "pasos_fallidos", "nota"]
with open(SALIDA, "wb") as fh:
    w = csv.DictWriter(fh, fieldnames=campos)
    w.writeheader()
    for f in filas:
        w.writerow(dict((k, unicode(v).encode("utf-8")) for k, v in f.items()))

ok = sum(1 for f in filas if f.get("veredicto") == 1)
system.write_message(Severity.Information,
                      "TERMINADO. Veredicto=1 en %d de %d combinaciones. Resultado: %s" %
                      (ok, len(filas), SALIDA))
