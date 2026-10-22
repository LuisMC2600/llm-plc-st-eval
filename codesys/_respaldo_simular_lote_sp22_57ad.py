# -*- coding: utf-8 -*-
"""
Simulacion por lotes con harnesses en CODESYS V3.5 SP22 Patch 3 -- criterio 1.
ScriptEngine (IronPython 2.7): sin f-strings.

Reemplaza a simular_lote.py (propuesta nunca probada) con las llamadas que las
sondas v1 y v2 confirmaron en SP22 Patch 3.

DOS MODOS (params_simular.json, que escribe ejecutar_simular_lote.ps1):
  "dobles"      Verifica los HARNESSES: cada doble de prueba (dobles/manifiesto.json)
                se simula con el harness de su tarea. Un harness queda verificado
                si en CODESYS real da el mismo veredicto (y el mismo paso de
                fallo) que predijo su validador en Python, en todos los ciclos.
  "respuestas"  Aplica los harnesses ya verificados a respuestas de modelos
                (<modelo>/<tarea>/<estrategia>/ejec_N.st) para medir el criterio 1.

POR CADA (elemento, ciclo): abre la plantilla limpia, fija el ciclo de la
MainTask, importa el FB y el harness, compila, simula en modo simulacion,
espera a que el harness emita veredicto (o vence el tiempo), lee veredicto y
resultado[], y cierra SIN GUARDAR.

NOTA METODOLOGICA: no modifica el texto de ninguna respuesta ni de ningun
harness; solo los importa y los ejecuta.
"""
import os
import re
import csv
import json
import time

EN_CODESYS = "projects" in globals()
AQUI = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()

# Duracion medida de cada harness (Validacion_Harnesses_CODESYS, seccion 5), en s.
DURACION_S = {"B1": 1.6, "B2": 12.9, "B3": 2.1, "B4": 1.5, "B5": 71.2, "B6": 9.7,
              "I1": 70.6, "I2": 62.6, "I3": 1.5, "I4": 9.2, "I5": 4.0, "I6": 0.8,
              "B7": 1.0, "B8": 2.3, "I7": 1.4, "I8": 10.3, "C3": 22.4,
              "A2": 125.6, "A3": 3.5}
FB_ESPERADO = {"B1": "FB_Motor", "B2": "FB_Valvula", "B3": "FB_Contador", "B4": "FB_Giro",
               "B5": "FB_Ventilador", "B6": "FB_Baliza", "I1": "FB_Semaforo", "I2": "FB_Llenado",
               "I3": "FB_Alarmas", "I4": "FB_EstrellaTriangulo", "I5": "FB_Clasificadora",
               "I6": "FB_Temperatura", "B8": "FB_Puerta",
               "I7": "FB_Duplex", "I8": "FB_Compresor",
               "C3": "PRG_Conversion", "A2": "FB_Batch", "A3": "FB_Com"}
# Tipo de POU exigido por el enunciado cuando no es FUNCTION_BLOCK.
TIPO_ESPERADO = {"C3": "PROGRAM"}

# Tareas en que el modelo elige el tipo de POU: el harness tiene una variante por
# tipo (PRG_Test_<T>_FUN/_FB/_PRG.st) y se elige segun lo que declare la respuesta.
# El tipo elegido se registra en la columna 'pou'; no forma parte del criterio 1.
POU_ELECCION = {"B7": "SelBomba"}
SUFIJO_POU = {"FUNCTION": "FUN", "FUNCTION_BLOCK": "FB", "PROGRAM": "PRG"}


def timeout_s(tarea):
    return max(10.0, DURACION_S.get(tarea, 60.0) * 1.5 + 5.0)


# ------------------------------------------------------------------ utilidades (identicas a compilar_lote_sp22.py)
def limpio(x, n=300):
    try:
        s = x if isinstance(x, basestring) else repr(x)  # noqa: F821
        s = u"".join(c if ord(c) < 128 else "?" for c in unicode(s))  # noqa: F821
    except NameError:
        s = x if isinstance(x, str) else repr(x)
        s = "".join(c if ord(c) < 128 else "?" for c in s)
    except Exception:
        s = "<no representable>"
    return str(s[:n]).replace("\n", " ").replace("\r", " ")


RE_CABECERA = re.compile(
    r"^[ \t]*(TYPE|FUNCTION_BLOCK|FUNCTION|PROGRAM)\b[ \t]+([A-Za-z_][A-Za-z0-9_]*)",
    re.IGNORECASE | re.MULTILINE)
RE_FIN = re.compile(r"^[ \t]*END_(TYPE|FUNCTION_BLOCK|FUNCTION|PROGRAM)\b[ \t]*;?[ \t]*$",
                    re.IGNORECASE | re.MULTILINE)
RE_RETORNO = re.compile(r"^[ \t]*FUNCTION[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]*:[ \t]*([A-Za-z_][A-Za-z0-9_]*)",
                        re.IGNORECASE)
RE_VAR_INICIO = re.compile(r"^[ \t]*VAR(_INPUT|_OUTPUT|_IN_OUT|_TEMP|_STAT|_INST|_EXTERNAL|_GLOBAL)?\b",
                           re.IGNORECASE)
RE_VAR_FIN = re.compile(r"^[ \t]*END_VAR\b", re.IGNORECASE)


def sin_comentarios(linea):
    return re.sub(r"\(\*.*?\*\)", "", re.sub(r"//.*$", "", linea)).strip()


def separar_unidades(texto):
    cabeceras = list(RE_CABECERA.finditer(texto))
    unidades = []
    for i, m in enumerate(cabeceras):
        tipo = m.group(1).upper()
        limite = cabeceras[i + 1].start() if i + 1 < len(cabeceras) else len(texto)
        tramo = texto[m.start():limite]
        fin = None
        for f in RE_FIN.finditer(tramo):
            if f.group(1).upper() == tipo:
                fin = f
        cuerpo = tramo[:fin.end()] if fin else tramo
        unidades.append((tipo, m.group(2), cuerpo.strip("\r\n")))
    return unidades


def partir_pou(texto_unidad):
    lineas = texto_unidad.splitlines()
    i, dentro_var, en_coment = 1, False, False
    while i < len(lineas):
        crudo = lineas[i]
        if en_coment:
            if "*)" in crudo:
                en_coment = False
            i += 1
            continue
        s = sin_comentarios(crudo)
        if "(*" in crudo and "*)" not in crudo.split("(*", 1)[1]:
            en_coment = True
            s = sin_comentarios(crudo.split("(*", 1)[0])
        if dentro_var:
            if RE_VAR_FIN.match(s):
                dentro_var = False
            i += 1
            continue
        if s == "" or s.startswith("{") or RE_VAR_INICIO.match(s):
            dentro_var = bool(RE_VAR_INICIO.match(s)) and not re.search(r"\bEND_VAR\b", s, re.IGNORECASE)
            i += 1
            continue
        break
    decl = "\n".join(lineas[:i]).rstrip()
    impl = "\n".join(lineas[i:])
    impl = re.sub(r"^[ \t]*END_(FUNCTION_BLOCK|FUNCTION|PROGRAM)\b[ \t]*;?[ \t]*$", "", impl,
                  flags=re.IGNORECASE | re.MULTILINE).strip()
    return decl, impl


def ultimo_paso(texto_harness):
    m = re.search(r"ULTIMO_PASO\s*:\s*INT\s*:=\s*(\d+)", texto_harness, re.IGNORECASE)
    return int(m.group(1)) if m else None


def a_int(valor):
    """'INT#2' -> 2 ; '2' -> 2 ; otro -> None"""
    try:
        return int(str(valor).split("#")[-1])
    except Exception:
        return None


def leer(ruta):
    with open(ruta, "rb") as fh:
        return fh.read().decode("utf-8", "replace")


# ------------------------------------------------------------------ CODESYS
def errores_compilacion():
    n, textos = 0, []
    for cat in system.get_message_categories():
        for m in system.get_message_objects(cat):
            sev = str(m.severity)
            if sev.endswith("Error") or sev.endswith("FatalError"):
                n += 1
                textos.append(limpio(m.text, 200))
    return n, textos


def limpiar_mensajes():
    for cat in system.get_message_categories():
        try:
            system.clear_messages(cat)
        except Exception:
            pass


def importar(app, texto):
    """Crea en la aplicacion cada unidad del texto (TYPE / FB / FUNCTION / PROGRAM)."""
    nombres = []
    for tipo, nombre, cuerpo in separar_unidades(texto):
        if tipo == "TYPE":
            dut = app.create_dut(nombre, DutType.Structure)
            dut.textual_declaration.replace(cuerpo)
        else:
            decl, impl = partir_pou(cuerpo)
            if tipo == "FUNCTION_BLOCK":
                pou = app.create_pou(nombre, PouType.FunctionBlock)
            elif tipo == "PROGRAM":
                pou = app.create_pou(nombre, PouType.Program)
            else:
                m = RE_RETORNO.match(cuerpo.splitlines()[0])
                pou = app.create_pou(nombre, PouType.Function, return_type=(m.group(1) if m else "BOOL"))
            pou.textual_declaration.replace(decl)
            pou.textual_implementation.replace(impl)
        nombres.append((tipo, nombre))
    return nombres


def elegir_harness(carpeta_h, tarea, unidades, r):
    """Devuelve el texto del harness. Para tareas con POU a eleccion, elige la
    variante segun el tipo de POU que declara la respuesta y lo anota en r['pou']."""
    if tarea in POU_ELECCION:
        nom = POU_ELECCION[tarea].lower()
        tipos = [t for t, n in unidades if n.lower() == nom]
        tipo = tipos[0] if tipos else None
        r["pou"] = tipo or "ninguno"
        if not tipo:
            r["nota"] = "interfaz: no define %s (define %s)" % (
                POU_ELECCION[tarea], ",".join(n for t, n in unidades) or "nada")
        ruta = os.path.join(carpeta_h, "PRG_Test_%s_%s.st" % (tarea, SUFIJO_POU.get(tipo, "FUN")))
    else:
        fb_nombres = [n for t, n in unidades if t == TIPO_ESPERADO.get(tarea, "FUNCTION_BLOCK")]
        if FB_ESPERADO[tarea] not in fb_nombres:
            r["nota"] = "interfaz: no define %s (define %s)" % (FB_ESPERADO[tarea], ",".join(fb_nombres) or "nada")
        ruta = os.path.join(carpeta_h, "PRG_Test_%s.st" % tarea)
    return leer(ruta)


def simular(plantilla, texto_fb, carpeta_h, tarea, ciclo_ms):
    """Devuelve dict con compila, veredicto, resultado, pasos_fallidos, nota, pou."""
    r = {"compila": "NA", "veredicto": "", "resultado": "", "pasos_fallidos": "", "nota": "", "errores": "",
         "pou": ""}
    nombre_h = "PRG_Test_%s" % tarea
    n_pasos = 0
    proyecto = projects.open(plantilla)
    oa = None
    try:
        app = proyecto.active_application
        mt = app.find("MainTask", True)[0]
        mt.interval = "t#%dms" % ciclo_ms
        texto_harness = elegir_harness(carpeta_h, tarea, importar(app, texto_fb), r)
        n_pasos = (ultimo_paso(texto_harness) or 0) + 1
        importar(app, texto_harness)
        mt.pous.add(nombre_h)
        limpiar_mensajes()
        app.build()
        n_err, textos = errores_compilacion()
        if n_err:
            r["compila"], r["errores"] = 0, n_err
            r["nota"] = (r["nota"] + " | " if r["nota"] else "") + (textos[0] if textos else "")
            return r
        r["compila"] = 1
        dev = proyecto.find("Device", True)[0]
        dev.set_simulation_mode(True)
        oa = online.create_online_application(app)
        # Descarga COMPLETA y reinicio en frio: con OnlineChangeOption.Try, CODESYS
        # hacia un cambio en linea que conservaba las variables de la simulacion
        # anterior (el veredicto ya estaba escrito y se leia al instante). Prueba
        # corta del 30-09-2026: todos los dobles de una tarea copiaban el
        # resultado del primero.
        oa.login(OnlineChangeOption.Never, True)
        oa.reset(ResetOption.Cold)
        v0 = a_int(oa.read_value("%s.veredicto" % nombre_h))
        if v0:
            r["nota"] = (r["nota"] + " | " if r["nota"] else "") + "veredicto no reiniciado (%s) antes de start" % v0
        oa.start()
        t0, v = time.time(), 0
        while time.time() - t0 < timeout_s(tarea):
            system.delay(250)
            v = a_int(oa.read_value("%s.veredicto" % nombre_h)) or 0
            if v != 0:
                break
        res = [a_int(x) for x in oa.read_values(["%s.resultado[%d]" % (nombre_h, i) for i in range(n_pasos)])]
        r["veredicto"] = v if v else "sin veredicto"
        r["resultado"] = ",".join(str(x) for x in res)
        r["pasos_fallidos"] = ",".join(str(i) for i, x in enumerate(res) if x == 2)
        r["seg_sim"] = round(time.time() - t0, 1)
        if v and r["seg_sim"] < 0.5 * DURACION_S.get(tarea, 0) and r["veredicto"] == 1:
            r["nota"] = (r["nota"] + " | " if r["nota"] else "") + "veredicto 1 antes de la duracion minima del harness: revisar"
    except Exception as e:
        r["nota"] = (r["nota"] + " | " if r["nota"] else "") + limpio("excepcion: %s: %s" % (type(e).__name__, e))
    finally:
        if oa is not None:
            for accion in ("stop", "logout"):
                try:
                    getattr(oa, accion)()
                except Exception:
                    pass
        try:
            proyecto.close()  # SIN guardar
        except Exception:
            pass
    return r


# ------------------------------------------------------------------ lote
def elementos(params):
    tareas = set(params.get("tareas") or DURACION_S.keys())
    if params["modo"] == "dobles":
        base = params["carpeta_dobles"]
        for d in json.load(open(os.path.join(base, "manifiesto.json"))):
            if d["tarea"] in tareas:
                yield {"tarea": d["tarea"], "id": d["doble"], "ruta": os.path.join(base, d["archivo"]),
                       "esperado": d["esperado"], "paso_esperado": d["paso_esperado"]}
    else:
        for dirpath, _, files in os.walk(params["carpeta_codigo"]):
            for f in sorted(files):
                if not f.lower().endswith(".st"):
                    continue
                partes = os.path.normpath(os.path.join(dirpath, f)).split(os.sep)
                modelo, tarea, estr = partes[-4], partes[-3], partes[-2]
                if tarea in tareas:
                    yield {"tarea": tarea, "id": "%s|%s|%s" % (modelo, estr, os.path.splitext(f)[0]),
                           "ruta": os.path.join(dirpath, f), "esperado": "", "paso_esperado": None}


def principal():
    params = json.load(open(os.path.join(AQUI, "params_simular.json")))
    plantilla = params.get("plantilla") or os.path.join(AQUI, "Plantilla_Simulacion.project")
    ciclos = params.get("ciclos_ms") or [4, 10]
    lista = sorted(elementos(params), key=lambda e: (e["tarea"], e["id"]))
    if int(params.get("limite", 0)):
        lista = lista[:int(params["limite"])]
    campos = ["tarea", "id", "ciclo_ms", "esperado", "paso_esperado", "compila", "veredicto", "resultado",
              "pasos_fallidos", "coincide", "seg_sim", "nota", "errores", "pou"]
    fh = open(params["salida_csv"], "wb")
    w = csv.DictWriter(fh, fieldnames=campos)
    w.writeheader()
    total = len(lista) * len(ciclos)
    k = 0
    for e in lista:
        texto_fb = leer(e["ruta"])
        for ciclo in ciclos:
            k += 1
            r = simular(plantilla, texto_fb, params["carpeta_harness"], e["tarea"], ciclo)
            coincide = ""
            if e["esperado"] != "":
                ok = (r["veredicto"] == e["esperado"])
                if ok and e["paso_esperado"] is not None:
                    ok = str(e["paso_esperado"]) in r["pasos_fallidos"].split(",")
                coincide = 1 if ok else 0
            fila = {"tarea": e["tarea"], "id": e["id"], "ciclo_ms": ciclo, "esperado": e["esperado"],
                    "paso_esperado": "" if e["paso_esperado"] is None else e["paso_esperado"],
                    "coincide": coincide}
            fila.update(r)
            w.writerow(dict((c, limpio(fila.get(c, ""), 300)) for c in campos))
            fh.flush()
            system.write_message(Severity.Information, "sim %d/%d %s %s %dms -> %s"
                                 % (k, total, e["tarea"], limpio(e["id"], 60), ciclo, r["veredicto"]))
    fh.close()


if EN_CODESYS:
    principal()
