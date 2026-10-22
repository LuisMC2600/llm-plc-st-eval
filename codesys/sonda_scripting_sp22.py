# -*- coding: utf-8 -*-
"""
Sonda del ScriptEngine de CODESYS V3.5 SP22 Patch 3 (IronPython 2.7).

PROPOSITO: antes de automatizar la compilacion y simulacion de las 720
respuestas, comprobar UNA POR UNA las llamadas de API que usan
compilar_lote.py y simular_lote.py, en tu version exacta de CODESYS. Nada
de lo que hace esta sonda toca datos del estudio: usa un FB de prueba
trivial (FB_Sonda) que no pertenece al corpus, abre la plantilla y la cierra
SIN GUARDAR.

SALIDA: codesys\sonda_resultado.txt (legible) y sonda_resultado.json. Cada
paso queda como OK / FALLA con el mensaje de excepcion, y para los objetos
clave se vuelca dir(), de modo que si un nombre de API cambio se vea cual
es el correcto.

LANZAR con ejecutar_sonda.ps1 (localiza CODESYS.exe y el perfil).
REQUISITO: codesys\Plantilla_Simulacion.project creada a mano una vez
(ver LEEME_AUTOMATIZACION.md, paso 3).

Nota: IronPython 2.7 -> sin f-strings, sin print() con end=, etc.
"""
import os
import sys
import json
import time
import traceback

AQUI = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
PLANTILLA = os.path.join(AQUI, "Plantilla_Simulacion.project")
SALIDA_TXT = os.path.join(AQUI, "sonda_resultado.txt")
SALIDA_JSON = os.path.join(AQUI, "sonda_resultado.json")

pasos = []
ctx = {}


def paso(nombre, funcion, *args):
    """Ejecuta una llamada, registra OK/FALLA y devuelve el resultado o None."""
    t0 = time.time()
    try:
        r = funcion(*args)
        pasos.append({"paso": nombre, "estado": "OK", "detalle": repr(r)[:300],
                      "seg": round(time.time() - t0, 2)})
        return r
    except Exception as e:
        pasos.append({"paso": nombre, "estado": "FALLA", "detalle": "%s: %s" % (type(e).__name__, e),
                      "traza": traceback.format_exc()[-800:], "seg": round(time.time() - t0, 2)})
        return None


def volcar(nombre, obj):
    try:
        miembros = [m for m in dir(obj) if not m.startswith("_")]
    except Exception as e:
        miembros = ["<dir fallo: %s>" % e]
    pasos.append({"paso": "dir(" + nombre + ")", "estado": "INFO", "detalle": ", ".join(miembros)})


def primero(lista):
    return lista[0] if lista else None


DECL_FB = """FUNCTION_BLOCK FB_Sonda
VAR_INPUT
    habilitar : BOOL;
END_VAR
VAR_OUTPUT
    cuenta : DINT;
END_VAR"""
IMPL_FB = """IF habilitar THEN
    cuenta := cuenta + 1;
END_IF"""
DECL_PRG = """PROGRAM PRG_Sonda
VAR
    fb : FB_Sonda;
    ciclos : DINT;
    veredicto : INT;
END_VAR"""
IMPL_PRG = """ciclos := ciclos + 1;
fb(habilitar := TRUE);
IF ciclos >= 50 AND fb.cuenta = ciclos THEN
    veredicto := 1;
END_IF"""

# ---------------------------------------------------------------- 0. entorno
pasos.append({"paso": "entorno", "estado": "INFO",
              "detalle": "python=%s | plantilla=%s | existe=%s" % (sys.version.split()[0], PLANTILLA, os.path.exists(PLANTILLA))})
volcar("system", system)
paso("system.get_script_args", lambda: system.get_script_args())
paso("sys.argv", lambda: list(sys.argv))

# ---------------------------------------------------------------- 1. proyecto
proyecto = paso("projects.open(plantilla)", lambda: projects.open(PLANTILLA))
if proyecto is None:
    proyecto = paso("projects.primary (alternativa)", lambda: projects.primary)
if proyecto is not None:
    volcar("proyecto", proyecto)
    app = paso("proyecto.active_application", lambda: proyecto.active_application)
    if app is None:
        app = paso("proyecto.find('Application', True)[0]", lambda: primero(proyecto.find("Application", True)))
    if app is not None:
        volcar("app", app)

        # ------------------------------------------------------------ 2. POUs
        fb = paso("app.create_pou(FB, PouType.FunctionBlock)", lambda: app.create_pou("FB_Sonda", PouType.FunctionBlock))
        if fb is None:
            fb = paso("app.create_pou(name=, type=) (alternativa)", lambda: app.create_pou(name="FB_Sonda", type=PouType.FunctionBlock))
        if fb is not None:
            volcar("pou_fb", fb)
            paso("fb.textual_declaration.replace", lambda: fb.textual_declaration.replace(DECL_FB))
            paso("fb.textual_implementation.replace", lambda: fb.textual_implementation.replace(IMPL_FB))
        prg = paso("app.create_pou(PRG, PouType.Program)", lambda: app.create_pou("PRG_Sonda", PouType.Program))
        if prg is not None:
            paso("prg.textual_declaration.replace", lambda: prg.textual_declaration.replace(DECL_PRG))
            paso("prg.textual_implementation.replace", lambda: prg.textual_implementation.replace(IMPL_PRG))
        # FUNCTION (necesario para B7 con POU a eleccion)
        paso("app.create_pou(FUNCTION, PouType.Function, return_type)",
             lambda: app.create_pou("FUN_Sonda", PouType.Function, "BOOL"))
        # DUT/TYPE (necesario para A5 con ST_Evento)
        paso("app.create_dut(ST_Sonda, DutType.Structure)", lambda: app.create_dut("ST_Sonda", DutType.Structure))

        # ------------------------------------------------------------ 3. tarea
        tc = paso("app.find('Task Configuration', True)[0]", lambda: primero(app.find("Task Configuration", True)))
        tarea = paso("app.find('MainTask', True)[0]", lambda: primero(app.find("MainTask", True)))
        if tarea is not None:
            volcar("MainTask", tarea)
            paso("MainTask.interval = 10 (ms)", lambda: setattr(tarea, "interval", "10"))
            paso("MainTask.interval_unit = TimeUnit.ms", lambda: setattr(tarea, "interval_unit", TimeUnit.ms))
            paso("MainTask.interval = 't#10ms' (alternativa)", lambda: setattr(tarea, "interval", "t#10ms"))
            paso("leer MainTask.interval", lambda: tarea.interval)
            pous = paso("MainTask.pous", lambda: tarea.pous)
            if pous is not None:
                volcar("MainTask.pous", pous)
                paso("MainTask.pous.add('PRG_Sonda')", lambda: pous.add("PRG_Sonda"))

        # ------------------------------------------------------------ 4. compilacion
        paso("app.build()", lambda: app.build())
        paso("proyecto.build() (alternativa)", lambda: proyecto.build())
        paso("app.generate_code()", lambda: app.generate_code())
        paso("system.get_messages(Severity.Error)", lambda: [str(m) for m in system.get_messages(Severity.Error)])
        paso("system.get_message_objects()", lambda: [str(m) for m in system.get_message_objects()][:20])

        # ------------------------------------------------------------ 5. simulacion
        dev = paso("proyecto.find('Device', True)[0]", lambda: primero(proyecto.find("Device", True)))
        if dev is None:
            dev = paso("app.parent (alternativa para el device)", lambda: app.parent.parent)
        if dev is not None:
            volcar("device", dev)
            paso("device.set_simulation_mode(True)", lambda: dev.set_simulation_mode(True))
            paso("device.get_simulation_mode()", lambda: dev.get_simulation_mode())
        oa = paso("online.create_online_application(app)", lambda: online.create_online_application(app))
        if oa is not None:
            volcar("online_app", oa)
            ok_login = paso("online_app.login(OnlineChangeOption.Try, True)", lambda: oa.login(OnlineChangeOption.Try, True))
            if ok_login is None and pasos[-1]["estado"] == "FALLA":
                paso("online_app.login(OnlineChangeOption.Never, True) (alternativa)", lambda: oa.login(OnlineChangeOption.Never, True))
            paso("online_app.start()", lambda: oa.start())
            paso("system.delay(3000)", lambda: system.delay(3000))
            for expr in ("PRG_Sonda.ciclos", "Application.PRG_Sonda.ciclos"):
                paso("online_app.read_value('%s')" % expr, lambda e=expr: str(oa.read_value(e)))
            paso("online_app.read_values([...veredicto, fb.cuenta])",
                 lambda: [str(v) for v in oa.read_values(["PRG_Sonda.veredicto", "PRG_Sonda.fb.cuenta"])])
            # Escritura de entradas (algunos harnesses podrian necesitarla)
            paso("online_app.set_prepared_value + write_prepared_values",
                 lambda: (oa.set_prepared_value("PRG_Sonda.ciclos", "0"), oa.write_prepared_values()))
            paso("online_app.stop()", lambda: oa.stop())
            paso("online_app.logout()", lambda: oa.logout())

    # ---------------------------------------------------------------- 6. cierre SIN guardar
    paso("proyecto.close() sin guardar", lambda: proyecto.close())

# ---------------------------------------------------------------- informe
ok = len([p for p in pasos if p["estado"] == "OK"])
falla = len([p for p in pasos if p["estado"] == "FALLA"])
with open(SALIDA_JSON, "w") as fh:
    json.dump(pasos, fh, indent=2)
lineas = ["SONDA ScriptEngine CODESYS - %s" % time.strftime("%Y-%m-%d %H:%M:%S"),
          "OK: %d   FALLA: %d" % (ok, falla), ""]
for p in pasos:
    lineas.append("[%-5s] %s" % (p["estado"], p["paso"]))
    lineas.append("        " + p["detalle"][:600])
with open(SALIDA_TXT, "w") as fh:
    fh.write("\n".join(lineas))
try:
    system.write_message(Severity.Information, "Sonda terminada: %d OK, %d FALLA -> %s" % (ok, falla, SALIDA_TXT))
except Exception:
    pass
