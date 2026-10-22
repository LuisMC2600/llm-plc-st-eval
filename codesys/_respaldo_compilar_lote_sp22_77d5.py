# -*- coding: utf-8 -*-
"""
Compilacion por lotes en CODESYS V3.5 SP22 Patch 3 -- criterio 2 de la rubrica.
ScriptEngine (IronPython 2.7): sin f-strings.

POR QUE ESTE SCRIPT REEMPLAZA A compilar_lote.py
  La sonda v2 (30-09-2026) demostro que CODESYS NO compila los POU que nada
  referencia: un FB con dos errores deliberados dio "0 errores". Importar la
  respuesta y pulsar build, como hacia compilar_lote.py, habria marcado como
  "compila" a cualquier respuesta. Aqui cada POU de la respuesta se instancia
  o se llama desde un programa envoltorio (PRG_Envoltorio) que se agrega a la
  MainTask; asi el compilador la procesa de verdad.

CONTROLES DEL INSTRUMENTO (igual que se validan los harnesses)
  Antes del lote se compilan dos dobles de prueba que NO son corpus: uno
  correcto (debe dar 0 errores) y uno con errores sembrados (debe dar >= 1).
  Si alguno no se comporta como se espera, el script se detiene sin procesar
  ninguna respuesta.

AISLAMIENTO
  Cada respuesta se compila en la plantilla recien abierta y se cierra SIN
  GUARDAR, de modo que ninguna respuesta contamina a la siguiente.

PARAMETROS
  get_script_args no existe en SP22: los parametros se leen de
  params_compilar.json (junto a este script), que escribe el lanzador
  ejecutar_compilar_lote.ps1.

SALIDA (CSV, una fila por respuesta)
  modelo, tarea, estrategia, ejecucion, archivo, pous, tipos, compila (1/0/NA),
  errores, advertencias, resumen_codesys, primer_error, nota, seg

NOTA METODOLOGICA: el script no modifica el texto de ninguna respuesta. Solo lo
separa en unidades (TYPE / FUNCTION_BLOCK / FUNCTION / PROGRAM), lo importa tal
cual y agrega un envoltorio que lo referencia.
"""
import os
import re
import sys
import csv
import json
import time

EN_CODESYS = "projects" in globals()
AQUI = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()

# ------------------------------------------------------------------ utilidades


def limpio(x, n=300):
    """Texto ASCII (los mensajes de CODESYS en espanol traen tildes)."""
    try:
        s = x if isinstance(x, basestring) else repr(x)  # noqa: F821 (IronPython 2.7)
        s = u"".join(c if ord(c) < 128 else "?" for c in unicode(s))  # noqa: F821
    except NameError:  # CPython 3 (modo prueba)
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
    """Devuelve [(tipo, nombre, texto_unidad)] en el orden de aparicion.

    Cada unidad va desde su cabecera hasta su END_<tipo> (incluido) o, si el
    modelo omitio el cierre, hasta la siguiente cabecera o el final.
    """
    cabeceras = list(RE_CABECERA.finditer(texto))
    unidades = []
    for i, m in enumerate(cabeceras):
        tipo = m.group(1).upper()
        inicio = m.start()
        limite = cabeceras[i + 1].start() if i + 1 < len(cabeceras) else len(texto)
        tramo = texto[inicio:limite]
        fin = None
        for f in RE_FIN.finditer(tramo):
            if f.group(1).upper() == tipo:
                fin = f
        cuerpo = tramo[:fin.end()] if fin else tramo
        unidades.append((tipo, m.group(2), cuerpo.strip("\r\n")))
    return unidades


def partir_pou(texto_unidad):
    """Separa declaracion (cabecera + bloques VAR) de implementacion.

    La implementacion excluye la linea END_<POU>, porque el editor de CODESYS
    no la lleva. Los comentarios entre bloques VAR quedan en la declaracion.
    """
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


def entradas_funcion(texto_unidad):
    """[(nombre, tipo)] de los bloques VAR_INPUT de una FUNCTION, en orden."""
    salida, dentro = [], False
    for crudo in texto_unidad.splitlines():
        s = sin_comentarios(crudo)
        if re.match(r"^VAR_INPUT\b", s, re.IGNORECASE):
            dentro = True
            s = re.sub(r"^VAR_INPUT\b", "", s, flags=re.IGNORECASE).strip()
        if not dentro:
            continue
        fin = re.search(r"\bEND_VAR\b", s, re.IGNORECASE)
        cuerpo = s[:fin.start()] if fin else s
        for decl in cuerpo.split(";"):
            m = re.match(r"^\s*([A-Za-z_][\w\s,]*?)\s*:\s*([^:=]+?)\s*(:=.*)?$", decl)
            if m:
                for nombre in m.group(1).split(","):
                    if nombre.strip():
                        salida.append((nombre.strip(), m.group(2).strip()))
        if fin:
            dentro = False
    return salida


def envoltorio(unidades):
    """Programa que referencia cada FB y FUNCTION de la respuesta.

    FB -> se declara una instancia y se llama sin argumentos (las entradas
    toman su valor por defecto; basta para que el compilador la procese).
    FUNCTION -> se llama asignando el resultado a una variable de su tipo de
    retorno. PROGRAM -> se llama directamente.
    """
    decl, impl = ["PROGRAM PRG_Envoltorio", "VAR"], []
    for k, (tipo, nombre, texto) in enumerate(unidades):
        if tipo == "FUNCTION_BLOCK":
            decl.append("    i%d : %s;" % (k, nombre))
            if not re.search(r"^[ \t]*VAR_IN_OUT\b", texto, re.IGNORECASE | re.MULTILINE):
                impl.append("i%d();" % k)  # con VAR_IN_OUT basta la declaracion
        elif tipo == "FUNCTION":
            # CODESYS exige TODAS las entradas de una FUNCTION (lo demostro el control
            # FUN_Control: "necesita exactamente 2 entradas"). Se declara en el
            # envoltorio una variable del mismo tipo por cada VAR_INPUT y se pasa.
            args = []
            for j, (var, tipo_var) in enumerate(entradas_funcion(texto)):
                decl.append("    a%d_%d : %s;" % (k, j, tipo_var))
                args.append("%s := a%d_%d" % (var, k, j))
            llamada = "%s(%s)" % (nombre, ", ".join(args))
            m = RE_RETORNO.match(texto.splitlines()[0])
            if m:
                decl.append("    r%d : %s;" % (k, m.group(1)))
                impl.append("r%d := %s;" % (k, llamada))
            else:
                impl.append("%s;" % llamada)
        elif tipo == "PROGRAM":
            impl.append("%s();" % nombre)
    decl.append("END_VAR")
    return "\n".join(decl), "\n".join(impl) if impl else ";"


def listar_respuestas(raiz):
    """(ruta, modelo, tarea, estrategia, ejecucion) desde <modelo>/<tarea>/<estrategia>/ejec_N.st"""
    salida = []
    for dirpath, _, files in os.walk(raiz):
        for f in sorted(files):
            if not f.lower().endswith(".st"):
                continue
            ruta = os.path.join(dirpath, f)
            partes = os.path.normpath(ruta).split(os.sep)
            if len(partes) < 4:
                continue
            salida.append((ruta, partes[-4], partes[-3], partes[-2],
                           os.path.splitext(f)[0].replace("ejec_", "")))
    return sorted(salida, key=lambda r: (r[1], r[2], r[3], r[4]))


# ------------------------------------------------------------------ dobles de prueba (no corpus)
CONTROL_OK = """FUNCTION_BLOCK FB_ControlOk
VAR_INPUT
    a : BOOL;
END_VAR
VAR_OUTPUT
    q : BOOL;
END_VAR
VAR
    t : TON;
END_VAR
t(IN := a, PT := T#1S);
q := t.Q;
END_FUNCTION_BLOCK"""

CONTROL_FUNCION = """FUNCTION FUN_Control : BOOL
VAR_INPUT
    a : BOOL;
    b : BOOL;
END_VAR
FUN_Control := a AND NOT b;
END_FUNCTION"""

CONTROL_ERROR = """FUNCTION_BLOCK FB_ControlError
VAR
    x : INT;
END_VAR
x := noDeclarada + 1;
x := TRUE;
END_FUNCTION_BLOCK"""


# ------------------------------------------------------------------ CODESYS

def mensajes_compilacion():
    """(n_errores, n_advertencias, resumen, [textos de error]) de todas las categorias."""
    errores, adv, resumen, textos, en_env = 0, 0, "", [], 0
    for cat in system.get_message_categories():
        for m in system.get_message_objects(cat):
            sev = str(m.severity)
            txt = limpio(m.text, 250)
            if "terminada" in txt.lower() or "finished" in txt.lower():
                resumen = txt
            if sev.endswith("Error") or sev.endswith("FatalError"):
                errores += 1
                pos = ""
                try:
                    pos = limpio(m.position_text, 80)
                except Exception:
                    pass
                textos.append(("%s %s" % (pos, txt)).strip())
                if "PRG_Envoltorio" in pos or "PRG_Envoltorio" in txt:
                    en_env += 1
            elif sev.endswith("Warning"):
                adv += 1
    return errores, adv, resumen, textos, en_env


def limpiar_mensajes():
    for cat in system.get_message_categories():
        try:
            system.clear_messages(cat)
        except Exception:
            pass


def compilar_texto(plantilla, texto):
    """Compila un texto de respuesta en la plantilla limpia. Devuelve dict."""
    r = {"pous": "", "tipos": "", "compila": "NA", "errores": "", "advertencias": "",
         "resumen_codesys": "", "primer_error": "", "nota": ""}
    unidades = separar_unidades(texto)
    r["pous"] = ";".join(u[1] for u in unidades)
    r["tipos"] = ";".join(u[0] for u in unidades)
    if not any(u[0] in ("FUNCTION_BLOCK", "FUNCTION", "PROGRAM") for u in unidades):
        r["compila"] = 0
        r["nota"] = "sin POU reconocible en la respuesta"
        return r
    proyecto = projects.open(plantilla)
    try:
        app = proyecto.active_application
        tarea = app.find("MainTask", True)[0]
        for tipo, nombre, cuerpo in unidades:
            if tipo == "TYPE":
                dut = app.create_dut(nombre, DutType.Structure)
                dut.textual_declaration.replace(cuerpo)
                continue
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
        d_env, i_env = envoltorio(unidades)
        env = app.create_pou("PRG_Envoltorio", PouType.Program)
        env.textual_declaration.replace(d_env)
        env.textual_implementation.replace(i_env)
        tarea.pous.add("PRG_Envoltorio")
        limpiar_mensajes()
        app.build()
        n_err, n_adv, resumen, textos, n_env = mensajes_compilacion()
        r["errores"], r["advertencias"], r["resumen_codesys"] = n_err, n_adv, resumen
        r["compila"] = 1 if n_err == 0 else 0
        if n_env:
            # Un error dentro del envoltorio es del instrumento, no de la respuesta:
            # no se puntua y se revisa a mano.
            r["compila"] = "NA"
            r["nota"] = "%d error(es) en PRG_Envoltorio: revisar a mano" % n_env
        r["primer_error"] = textos[0] if textos else ""
    except Exception as e:
        r["compila"] = "NA"
        r["nota"] = limpio("excepcion al importar: %s: %s" % (type(e).__name__, e))
    finally:
        try:
            proyecto.close()  # SIN guardar: la plantilla queda limpia para la siguiente
        except Exception:
            pass
    return r


def principal():
    params = json.load(open(os.path.join(AQUI, "params_compilar.json")))
    carpeta, salida = params["carpeta_codigo"], params["salida_csv"]
    plantilla = params.get("plantilla") or os.path.join(AQUI, "Plantilla_Simulacion.project")
    limite = int(params.get("limite", 0))

    # 1. Controles del instrumento
    c_ok = compilar_texto(plantilla, CONTROL_OK)
    c_err = compilar_texto(plantilla, CONTROL_ERROR)
    c_fun = compilar_texto(plantilla, CONTROL_FUNCION)  # informativo: valida el envoltorio de FUNCTION (B7)
    controles = {"control_ok": c_ok, "control_error": c_err, "control_funcion": c_fun}
    json.dump(controles, open(salida + ".controles.json", "w"), indent=2)
    if not (c_ok["compila"] == 1 and c_err["compila"] == 0 and int(c_err["errores"] or 0) >= 1):
        system.write_message(Severity.Error, "CONTROLES FALLIDOS: el instrumento no discrimina. Ver " + salida + ".controles.json")
        return

    # 2. Lote
    respuestas = listar_respuestas(carpeta)
    if limite:
        respuestas = respuestas[:limite]
    campos = ["modelo", "tarea", "estrategia", "ejecucion", "archivo", "pous", "tipos", "compila",
              "errores", "advertencias", "resumen_codesys", "primer_error", "nota", "seg"]
    fh = open(salida, "wb")
    w = csv.DictWriter(fh, fieldnames=campos)
    w.writeheader()
    for k, (ruta, modelo, tarea, estr, ejec) in enumerate(respuestas):
        t0 = time.time()
        with open(ruta, "rb") as f:
            texto = f.read().decode("utf-8", "replace")
        r = compilar_texto(plantilla, texto)
        r.update({"modelo": modelo, "tarea": tarea, "estrategia": estr, "ejecucion": ejec,
                  "archivo": limpio(os.path.relpath(ruta, carpeta), 200), "seg": round(time.time() - t0, 1)})
        w.writerow(dict((c, limpio(r.get(c, ""), 300)) for c in campos))
        fh.flush()
        if (k + 1) % 10 == 0:
            system.write_message(Severity.Information, "compiladas %d/%d" % (k + 1, len(respuestas)))
    fh.close()
    system.write_message(Severity.Information, "Lote terminado: %d respuestas -> %s" % (len(respuestas), salida))


if EN_CODESYS:
    principal()
