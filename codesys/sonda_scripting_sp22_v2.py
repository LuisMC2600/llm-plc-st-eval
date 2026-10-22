# -*- coding: utf-8 -*-
"""
Sonda v2 del ScriptEngine de CODESYS V3.5 SP22 Patch 3 (IronPython 2.7).

La v1 (29-09-2026) confirmo que la cadena completa funciona: abrir plantilla,
crear POUs, fijar ciclo de MainTask ('t#10ms'), app.build(), simulacion,
login, start y read_value('PRG_Sonda.ciclos') -> DINT#285 tras 3 s. Se cayo
al escribir el informe por un mensaje de error con caracteres no ASCII.

Esta v2 corrige eso y prueba lo que falto:
  A. FUNCTION con return_type por nombre (B7 con POU a eleccion).
  B. Como detectar un ERROR DE COMPILACION (criterio 2): POU con error a
     proposito, build y lectura de mensajes por categoria.
  C. read_values, escritura de variables (set_prepared_value), stop,
     logout, y un SEGUNDO ciclo completo en la misma sesion (como hara el
     lote: una respuesta tras otra) para medir el tiempo por iteracion.
  D. Paso de parametros al script sin get_script_args (no existe en SP22).
Nada de esto toca datos del estudio; la plantilla se cierra sin guardar.
"""
import os
import sys
import json
import time
import traceback

AQUI = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
PLANTILLA = os.path.join(AQUI, "Plantilla_Simulacion.project")
SALIDA_TXT = os.path.join(AQUI, "sonda_v2_resultado.txt")
SALIDA_JSON = os.path.join(AQUI, "sonda_v2_resultado.json")
pasos = []


def limpio(x, n=600):
    """Texto solo ASCII (los mensajes de CODESYS en espanol rompian la v1)."""
    try:
        s = x if isinstance(x, basestring) else repr(x)
    except Exception:
        s = "<no representable>"
    try:
        s = u"".join(c if ord(c) < 128 else "?" for c in unicode(s))
    except Exception:
        s = "<texto no convertible>"
    return str(s[:n])


def paso(nombre, funcion):
    t0 = time.time()
    try:
        r = funcion()
        pasos.append({"paso": nombre, "estado": "OK", "detalle": limpio(r), "seg": round(time.time() - t0, 2)})
        return r
    except Exception as e:
        pasos.append({"paso": nombre, "estado": "FALLA", "detalle": limpio("%s: %s" % (type(e).__name__, e)),
                      "traza": limpio(traceback.format_exc(), 900), "seg": round(time.time() - t0, 2)})
        return None


def info(nombre, texto):
    pasos.append({"paso": nombre, "estado": "INFO", "detalle": limpio(texto, 1500)})


def volcar(nombre, obj):
    try:
        info("dir(" + nombre + ")", ", ".join(m for m in dir(obj) if not m.startswith("_")))
    except Exception as e:
        info("dir(" + nombre + ")", "dir fallo: %s" % e)


def primero(lista):
    return lista[0] if lista else None


def escribir_informe():
    ok = len([p for p in pasos if p["estado"] == "OK"])
    falla = len([p for p in pasos if p["estado"] == "FALLA"])
    lineas = ["SONDA v2 ScriptEngine CODESYS - %s" % time.strftime("%Y-%m-%d %H:%M:%S"),
              "OK: %d   FALLA: %d" % (ok, falla), ""]
    for p in pasos:
        lineas.append("[%-5s] %s  (%s s)" % (p["estado"], p["paso"], p.get("seg", "")))
        lineas.append("        " + p["detalle"])
    fh = open(SALIDA_TXT, "w")
    fh.write("\n".join(lineas))
    fh.close()
    try:
        fh = open(SALIDA_JSON, "w")
        json.dump(pasos, fh, indent=2)
        fh.close()
    except Exception as e:
        info("json", "no se pudo escribir json: %s" % e)


DECL_FB = "FUNCTION_BLOCK FB_Sonda\nVAR_INPUT\n    habilitar : BOOL;\nEND_VAR\nVAR_OUTPUT\n    cuenta : DINT;\nEND_VAR"
IMPL_FB = "IF habilitar THEN\n    cuenta := cuenta + 1;\nEND_IF"
DECL_PRG = "PROGRAM PRG_Sonda\nVAR\n    fb : FB_Sonda;\n    hab : BOOL := TRUE;\n    ciclos : DINT;\n    veredicto : INT;\nEND_VAR"
IMPL_PRG = "ciclos := ciclos + 1;\nfb(habilitar := hab);\nIF ciclos >= 50 THEN\n    veredicto := 1;\nEND_IF"
DECL_FUN = "FUNCTION FUN_Sonda : BOOL\nVAR_INPUT\n    a : BOOL;\n    b : BOOL;\nEND_VAR"
IMPL_FUN = "FUN_Sonda := a AND NOT b;"
# POU con errores deliberados: variable no declarada y tipo incompatible
DECL_ERR = "FUNCTION_BLOCK FB_ConError\nVAR\n    x : INT;\nEND_VAR"
IMPL_ERR = "x := noDeclarada + 1;\nx := TRUE;"


def mensajes():
    """Devuelve lista de (categoria, texto) de todos los mensajes actuales."""
    salida = []
    for cat in system.get_message_categories():
        desc = system.get_message_category_description(cat)
        try:
            for m in system.get_message_objects(cat):
                salida.append((limpio(desc, 60), limpio(m, 250)))
        except Exception:
            for m in system.get_messages(cat):
                salida.append((limpio(desc, 60), limpio(m, 250)))
    return salida


# ============================================================ 0. entorno y parametros
info("entorno", "python=%s | plantilla existe=%s" % (sys.version.split()[0], os.path.exists(PLANTILLA)))
info("D. parametros", "sys.argv=%s | env SONDA_PARAM=%s | archivo params.json existe=%s"
     % (sys.argv, os.environ.get("SONDA_PARAM"), os.path.exists(os.path.join(AQUI, "params.json"))))

proyecto = paso("projects.open(plantilla)", lambda: projects.open(PLANTILLA))
if proyecto is not None:
    app = paso("proyecto.active_application", lambda: proyecto.active_application)
    tarea = paso("find MainTask", lambda: primero(app.find("MainTask", True)))
    paso("MainTask.interval = 't#10ms'", lambda: setattr(tarea, "interval", "t#10ms"))

    # ---------------------------------------------------------- A. FUNCTION
    fun = paso("A. create_pou(FUNCTION, return_type='BOOL')",
               lambda: app.create_pou("FUN_Sonda", PouType.Function, return_type="BOOL"))
    if fun is not None:
        paso("A. FUNCTION declaracion", lambda: fun.textual_declaration.replace(DECL_FUN))
        paso("A. FUNCTION implementacion", lambda: fun.textual_implementation.replace(IMPL_FUN))

    # ---------------------------------------------------------- B. deteccion de errores
    info("B. categorias de mensajes", ", ".join(
        "%s=%s" % (c, system.get_message_category_description(c)) for c in system.get_message_categories()))
    err = paso("B. create_pou(FB_ConError)", lambda: app.create_pou("FB_ConError", PouType.FunctionBlock))
    if err is not None:
        paso("B. FB_ConError declaracion", lambda: err.textual_declaration.replace(DECL_ERR))
        paso("B. FB_ConError implementacion", lambda: err.textual_implementation.replace(IMPL_ERR))
    paso("B. clear_messages", lambda: system.clear_messages())
    paso("B. app.build() con error", lambda: app.build())
    msgs = paso("B. mensajes tras build con error", mensajes)
    if msgs:
        info("B. primeros mensajes", " || ".join("[%s] %s" % m for m in msgs[:8]))
        m0 = None
        for cat in system.get_message_categories():
            obs = list(system.get_message_objects(cat))
            if obs:
                m0 = obs[0]
                break
        if m0 is not None:
            volcar("objeto_mensaje", m0)
            for attr in ("severity", "text", "description", "position", "object"):
                paso("B. mensaje.%s" % attr, lambda a=attr: getattr(m0, a))
    paso("B. borrar FB_ConError", lambda: err.remove())
    paso("B. clear_messages", lambda: system.clear_messages())
    paso("B. app.build() limpio", lambda: app.build())
    paso("B. mensajes tras build limpio", mensajes)

    # ---------------------------------------------------------- POUs de prueba y simulacion
    fb = paso("create FB_Sonda", lambda: app.create_pou("FB_Sonda", PouType.FunctionBlock))
    paso("FB decl", lambda: fb.textual_declaration.replace(DECL_FB))
    paso("FB impl", lambda: fb.textual_implementation.replace(IMPL_FB))
    prg = paso("create PRG_Sonda", lambda: app.create_pou("PRG_Sonda", PouType.Program))
    paso("PRG decl", lambda: prg.textual_declaration.replace(DECL_PRG))
    paso("PRG impl", lambda: prg.textual_implementation.replace(IMPL_PRG))
    paso("MainTask.pous.add('PRG_Sonda')", lambda: tarea.pous.add("PRG_Sonda"))
    paso("build final", lambda: app.build())
    paso("mensajes build final", mensajes)
    dev = paso("find Device", lambda: primero(proyecto.find("Device", True)))
    paso("set_simulation_mode(True)", lambda: dev.set_simulation_mode(True))

    # ---------------------------------------------------------- C. dos iteraciones
    for it in (1, 2):
        t_it = time.time()
        oa = paso("C%d. create_online_application" % it, lambda: online.create_online_application(app))
        if oa is None:
            break
        paso("C%d. login" % it, lambda: oa.login(OnlineChangeOption.Try, True))
        paso("C%d. reset(ResetOption.Cold)" % it, lambda: oa.reset(ResetOption.Cold))
        paso("C%d. start" % it, lambda: oa.start())
        paso("C%d. delay 1000" % it, lambda: system.delay(1000))
        paso("C%d. read_value ciclos" % it, lambda: oa.read_value("PRG_Sonda.ciclos"))
        paso("C%d. read_values [veredicto, fb.cuenta]" % it,
             lambda: [limpio(v) for v in oa.read_values(["PRG_Sonda.veredicto", "PRG_Sonda.fb.cuenta"])])
        paso("C%d. set_prepared_value hab=FALSE" % it, lambda: oa.set_prepared_value("PRG_Sonda.hab", "FALSE"))
        paso("C%d. write_prepared_values" % it, lambda: oa.write_prepared_values())
        paso("C%d. delay 500" % it, lambda: system.delay(500))
        paso("C%d. fb.cuenta congelada?" % it,
             lambda: [limpio(oa.read_value("PRG_Sonda.fb.cuenta")), limpio(oa.read_value("PRG_Sonda.ciclos"))])
        paso("C%d. stop" % it, lambda: oa.stop())
        paso("C%d. logout" % it, lambda: oa.logout())
        info("C%d. duracion iteracion" % it, "%.2f s" % (time.time() - t_it))

    paso("proyecto.close() sin guardar", lambda: proyecto.close())

escribir_informe()
try:
    system.write_message(Severity.Information, "Sonda v2 terminada -> " + SALIDA_TXT)
except Exception:
    pass
