# -*- coding: utf-8 -*-
"""
Genera los dobles de prueba en ST para verificar los 12 harnesses del piloto
en CODESYS real. Cada doble es la traduccion a ST de una implementacion
sintetica de codesys/validar_harness_<T>.py (correcta o con un defecto
sembrado), con el veredicto y el paso de fallo que la validacion en Python
predijo.

NO SON CORPUS: son instrumentos para validar los harnesses (regla 5 de
CLAUDE.md). Ningun doble se envia a un modelo ni se mezcla con respuestas.

Cuando la implementacion en Python acumula tiempo con dt, el doble mide el dt
real de cada scan con TIME() (funcion de CODESYS, admisible en un instrumento)
para ser una traduccion fiel e independiente del ciclo de la MainTask.

Salida: dobles/<tarea>/<nn>_<nombre>.st y dobles/manifiesto.json
"""
import json
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
D = []  # (tarea, nombre, esperado, paso, texto)


def fb(nombre_fb, decl_io, decl_var, cuerpo):
    return ("FUNCTION_BLOCK %s\n%s\nVAR\n%s\nEND_VAR\n%s\nEND_FUNCTION_BLOCK\n"
            % (nombre_fb, decl_io.strip("\n"), decl_var.strip("\n") or "    nada : BOOL;", cuerpo.strip("\n")))


def doble(tarea, nombre, esperado, paso, texto):
    cab = "(* DOBLE DE PRUEBA %s/%s - NO ES CORPUS. Esperado: veredicto %d%s *)\n" % (
        tarea, nombre, esperado, "" if paso is None else ", falla en el paso %d" % paso)
    D.append((tarea, nombre, esperado, paso, cab + texto))


# Bloque de medicion del dt real de cada scan (para dobles con tiempo acumulado)
DT_VAR = """    tAhora : TIME;
    tPrev : TIME;
    dScan : TIME;
    init : BOOL;"""
DT_COD = """tAhora := TIME();
IF NOT init THEN
    tPrev := tAhora;
    init := TRUE;
END_IF
dScan := tAhora - tPrev;
tPrev := tAhora;"""

# ============================================================== B1 FB_Motor
IO_B1 = """VAR_INPUT
    btnMarcha : BOOL;
    btnParo : BOOL;
    btnEmerg : BOOL;
END_VAR
VAR_OUTPUT
    motorOn : BOOL;
END_VAR"""
doble("B1", "Correcta", 1, None, fb("FB_Motor", IO_B1, "    bloqueo : BOOL;", """
IF btnEmerg THEN
    motorOn := FALSE;
    bloqueo := TRUE;
ELSE
    IF bloqueo AND NOT btnMarcha THEN
        bloqueo := FALSE;
    END_IF
    IF btnParo THEN
        motorOn := FALSE;
    ELSIF btnMarcha AND NOT bloqueo THEN
        motorOn := TRUE;
    END_IF
END_IF"""))
doble("B1", "SinEnclavamiento", 2, 2, fb("FB_Motor", IO_B1, "", """
motorOn := btnMarcha AND NOT btnParo AND NOT btnEmerg;"""))
doble("B1", "RearranqueTrasEmergencia", 2, 6, fb("FB_Motor", IO_B1, "", """
IF btnParo OR btnEmerg THEN
    motorOn := FALSE;
ELSIF btnMarcha THEN
    motorOn := TRUE;
END_IF"""))
doble("B1", "EmergenciaNoDomina", 2, 5, fb("FB_Motor", IO_B1, "", """
IF btnMarcha THEN
    motorOn := TRUE;
ELSIF btnParo OR btnEmerg THEN
    motorOn := FALSE;
END_IF"""))
doble("B1", "ParoInvertido", 2, 1, fb("FB_Motor", IO_B1, "", """
IF btnEmerg OR NOT btnParo THEN
    motorOn := FALSE;
ELSIF btnMarcha THEN
    motorOn := TRUE;
END_IF"""))

# ============================================================== B2 FB_Valvula
IO_B2 = """VAR_INPUT
    nivelAlto : BOOL;
END_VAR
VAR_OUTPUT
    valvula : BOOL;
END_VAR"""
doble("B2", "Correcta", 1, None, fb("FB_Valvula", IO_B2, "    t : TON;", """
t(IN := nivelAlto, PT := T#5S);
valvula := t.Q;"""))
doble("B2", "TofEnVezDeTon", 2, 1, fb("FB_Valvula", IO_B2, "    t : TOF;", """
t(IN := nivelAlto, PT := T#5S);
valvula := t.Q;"""))
doble("B2", "PresetCorto", 2, 1, fb("FB_Valvula", IO_B2, "    t : TON;", """
t(IN := nivelAlto, PT := T#2S);
valvula := t.Q;"""))
doble("B2", "SinCierreInmediato", 2, 3, fb("FB_Valvula", IO_B2, "    t : TON;", """
t(IN := nivelAlto, PT := T#5S);
IF t.Q THEN
    valvula := TRUE;
END_IF"""))
doble("B2", "UnSoloDisparo", 2, 4, fb("FB_Valvula", IO_B2, "    t : TON;\n    yaAbrio : BOOL;", """
t(IN := nivelAlto, PT := T#5S);
IF t.Q AND NOT yaAbrio THEN
    valvula := TRUE;
    yaAbrio := TRUE;
END_IF
IF NOT nivelAlto THEN
    valvula := FALSE;
END_IF"""))

# ============================================================== B3 FB_Contador
IO_B3 = """VAR_INPUT
    sensorPieza : BOOL;
    btnReset : BOOL;
END_VAR
VAR_OUTPUT
    loteListo : BOOL;
    cuenta : INT;
END_VAR"""


def b3(nombre, esperado, paso, porFlanco=True, preset=12, resetApaga=True):
    cond = "sensorPieza AND NOT prev" if porFlanco else "sensorPieza"
    apaga = "\n    loteListo := FALSE;" if resetApaga else ""
    doble("B3", nombre, esperado, paso, fb("FB_Contador", IO_B3, "    prev : BOOL;", """
IF btnReset THEN
    cuenta := 0;%s
ELSIF %s THEN
    cuenta := cuenta + 1;
END_IF
IF cuenta >= %d THEN
    loteListo := TRUE;
END_IF
prev := sensorPieza;""" % (apaga, cond, preset)))


b3("Correcta", 1, None)
b3("CuentaPorNivel", 2, 2, porFlanco=False)
b3("PresetIncorrecto", 2, 4, preset=10)
b3("ResetIncompleto", 2, 6, resetApaga=False)

# ============================================================== B4 FB_Giro
IO_B4 = """VAR_INPUT
    btnFwd : BOOL;
    btnRev : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    fwd : BOOL;
    rev : BOOL;
END_VAR"""
doble("B4", "Correcta", 1, None, fb("FB_Giro", IO_B4, "", """
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;
ELSE
    IF btnFwd AND NOT rev THEN
        fwd := TRUE;
    END_IF
    IF btnRev AND NOT fwd THEN
        rev := TRUE;
    END_IF
END_IF"""))
doble("B4", "SinEnclavamiento", 2, 2, fb("FB_Giro", IO_B4, "", """
fwd := btnFwd AND NOT btnParo AND NOT btnRev;
rev := btnRev AND NOT btnParo AND NOT btnFwd;"""))
doble("B4", "InversionDirecta", 2, 3, fb("FB_Giro", IO_B4, "", """
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;
ELSIF btnFwd THEN
    fwd := TRUE;
    rev := FALSE;
ELSIF btnRev THEN
    rev := TRUE;
    fwd := FALSE;
END_IF"""))
doble("B4", "SinInterlock", 2, None, fb("FB_Giro", IO_B4, "", """
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;
ELSE
    IF btnFwd THEN
        fwd := TRUE;
    END_IF
    IF btnRev THEN
        rev := TRUE;
    END_IF
END_IF"""))
doble("B4", "CarreraDeInterlock", 2, None, fb("FB_Giro", IO_B4, "    fwdPrev : BOOL;\n    revPrev : BOOL;", """
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;
ELSE
    IF btnFwd AND NOT revPrev THEN
        fwd := TRUE;
    END_IF
    IF btnRev AND NOT fwdPrev THEN
        rev := TRUE;
    END_IF
END_IF
fwdPrev := fwd;
revPrev := rev;"""))

# ============================================================== B5 FB_Ventilador
IO_B5 = """VAR_INPUT
    quemadorOn : BOOL;
END_VAR
VAR_OUTPUT
    ventilador : BOOL;
END_VAR"""
for nombre, pt, paso in (("Correcta", "T#30S", None), ("TiempoCorto", "T#10S", 2), ("TiempoLargo", "T#60S", 3)):
    doble("B5", nombre, 1 if paso is None else 2, paso, fb("FB_Ventilador", IO_B5, "    t : TOF;", """
t(IN := quemadorOn, PT := %s);
ventilador := t.Q;""" % pt))
doble("B5", "SinRetardo", 2, 2, fb("FB_Ventilador", IO_B5, "", "ventilador := quemadorOn;"))
doble("B5", "TonEnVezDeTof", 2, 1, fb("FB_Ventilador", IO_B5, "    t : TON;", """
t(IN := quemadorOn, PT := T#30S);
ventilador := t.Q;"""))
doble("B5", "SinRearme", 2, 5, fb("FB_Ventilador", IO_B5, DT_VAR + "\n    acum : TIME;", DT_COD + """
IF quemadorOn THEN
    ventilador := TRUE;          (* no reinicia el acumulador *)
ELSE
    acum := acum + dScan;
    IF acum >= T#30S THEN
        ventilador := FALSE;
    END_IF
END_IF"""))
doble("B5", "RearmeCorto", 2, 7, fb("FB_Ventilador", IO_B5, DT_VAR + "\n    acum : TIME;\n    ciclos : INT;\n    prev : BOOL;\n    pt : TIME;", DT_COD + """
IF quemadorOn THEN
    ventilador := TRUE;
    acum := T#0S;
ELSE
    IF prev THEN
        ciclos := ciclos + 1;    (* flanco de bajada del quemador *)
    END_IF
    acum := acum + dScan;
    IF ciclos <= 1 THEN
        pt := T#30S;
    ELSE
        pt := T#15S;
    END_IF
    IF acum >= pt THEN
        ventilador := FALSE;
    END_IF
END_IF
prev := quemadorOn;"""))

# ============================================================== B6 FB_Baliza
IO_B6 = """VAR_INPUT
    alarma : BOOL;
END_VAR
VAR_OUTPUT
    lampara : BOOL;
END_VAR"""


def oscilador(t_on, t_off, arranca_encendida):
    flanco = """
IF NOT prevAlarma THEN
    lampara := TRUE;             (* enciende en el flanco de alarma *)
END_IF""" if arranca_encendida else ""
    return """
IF NOT alarma THEN
    lampara := FALSE;
    t1(IN := FALSE, PT := %(off)s);
    t2(IN := FALSE, PT := %(on)s);
    prevAlarma := FALSE;
ELSE%(flanco)s
    prevAlarma := TRUE;
    IF lampara THEN
        t1(IN := FALSE, PT := %(off)s);
        t2(IN := TRUE, PT := %(on)s);
        IF t2.Q THEN
            lampara := FALSE;
        END_IF
    ELSE
        t2(IN := FALSE, PT := %(on)s);
        t1(IN := TRUE, PT := %(off)s);
        IF t1.Q THEN
            lampara := TRUE;
        END_IF
    END_IF
END_IF""" % {"on": t_on, "off": t_off, "flanco": flanco.replace("\n", "\n    ")}


VAR_OSC = "    t1 : TON;\n    t2 : TON;\n    prevAlarma : BOOL;"
doble("B6", "CorrectaInicioOFF", 1, None, fb("FB_Baliza", IO_B6, VAR_OSC, oscilador("T#1S", "T#1S", False)))
doble("B6", "CorrectaInicioON", 1, None, fb("FB_Baliza", IO_B6, VAR_OSC, oscilador("T#1S", "T#1S", True)))
doble("B6", "Periodo1500", 2, 1, fb("FB_Baliza", IO_B6, VAR_OSC, oscilador("T#1500MS", "T#1500MS", True)))
doble("B6", "Periodo500", 2, 1, fb("FB_Baliza", IO_B6, VAR_OSC, oscilador("T#500MS", "T#500MS", True)))
doble("B6", "Asimetrico", 2, 1, fb("FB_Baliza", IO_B6, VAR_OSC, oscilador("T#1S", "T#2S", True)))
doble("B6", "SiempreEncendida", 2, 1, fb("FB_Baliza", IO_B6, "", "lampara := alarma;"))
# NoApagaSinAlarma: el oscilador ve una alarma permanente desde la primera vez
doble("B6", "NoApagaSinAlarma", 2, 2, fb("FB_Baliza", IO_B6, VAR_OSC + "\n    visto : BOOL;\n    alarmaEf : BOOL;", """
IF alarma THEN
    visto := TRUE;
END_IF
alarmaEf := visto OR alarma;""" + oscilador("T#1S", "T#1S", True).replace("alarma THEN", "alarmaEf THEN")))

# ============================================================== I1 FB_Semaforo
IO_I1 = """VAR_INPUT
    habilitado : BOOL;
END_VAR
VAR_OUTPUT
    luzV : BOOL;
    luzA : BOOL;
    luzR : BOOL;
END_VAR"""
VAR_I1 = DT_VAR + "\n    estado : INT;\n    t : TIME;\n    tParp : TIME;\n    parp : BOOL%s;\n    prevHab : BOOL;"
INTERMITENTE = {
    "normal": """    luzV := FALSE;
    luzR := FALSE;
    tParp := tParp + dScan;
    IF tParp >= %(tp)s THEN
        tParp := T#0S;
        parp := NOT parp;
    END_IF
    luzA := parp;""",
    "apagado": """    luzV := FALSE;
    luzA := FALSE;
    luzR := FALSE;""",
    "conRojo": """    luzV := FALSE;
    tParp := tParp + dScan;
    IF tParp >= %(tp)s THEN
        tParp := T#0S;
        parp := NOT parp;
    END_IF
    luzA := parp;
    luzR := NOT parp;""",
}


def i1(nombre, esperado, paso, tV="T#20S", tR="T#15S", tp="T#1S", modo="normal", reinicia=True, parpIni=False):
    reinicio = """
    IF NOT prevHab THEN
        estado := 0;
        t := T#0S;
        parp := FALSE;
        tParp := T#0S;
    END_IF""" if reinicia else ""
    cuerpo = DT_COD + """
IF NOT habilitado THEN
%(inter)s
    prevHab := FALSE;
ELSE%(reinicio)s
    prevHab := TRUE;
    t := t + dScan;
    CASE estado OF
        0:
            luzV := TRUE; luzA := FALSE; luzR := FALSE;
            IF t >= %(tV)s THEN estado := 1; t := T#0S; END_IF
        1:
            luzV := FALSE; luzA := TRUE; luzR := FALSE;
            IF t >= T#4S THEN estado := 2; t := T#0S; END_IF
    ELSE
            luzV := FALSE; luzA := FALSE; luzR := TRUE;
            IF t >= %(tR)s THEN estado := 0; t := T#0S; END_IF
    END_CASE
END_IF""" % {"inter": INTERMITENTE[modo] % {"tp": tp}, "reinicio": reinicio, "tV": tV, "tR": tR}
    doble("I1", nombre, esperado, paso, fb("FB_Semaforo", IO_I1, VAR_I1 % (" := TRUE" if parpIni else ""), cuerpo))


i1("Correcta", 1, None)
i1("TiemposCambiados", 2, 2, tV="T#15S", tR="T#20S")
i1("ParpadeoLento", 2, 7, tp="T#1500MS")
i1("SinIntermitente", 2, 7, modo="apagado")
i1("IntermitenteConRojo", 2, 7, modo="conRojo")
i1("IntermitenteConRojoFaseInversa", 2, 7, modo="conRojo", parpIni=True)
i1("NoReinicia", 2, 8, reinicia=False)

# ============================================================== I2 FB_Llenado
IO_I2 = """VAR_INPUT
    nivelAlto : BOOL;
    nivelBajo : BOOL;
    btnInicio : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    vLlenado : BOOL;
    motorMezcla : BOOL;
    vDescarga : BOOL;
END_VAR"""
VAR_I2 = DT_VAR + "\n    estado : INT;\n    t : TIME;"
SECUENCIA_I2 = """
CASE estado OF
    0:
        vLlenado := FALSE; motorMezcla := FALSE; vDescarga := FALSE;
        IF btnInicio THEN estado := 1; END_IF
    1:
        vLlenado := TRUE; motorMezcla := FALSE; vDescarga := FALSE;
        IF nivelAlto THEN estado := %(tras_llenado)s; t := T#0S; END_IF
    2:
        vLlenado := FALSE; motorMezcla := TRUE; vDescarga := FALSE;
        t := t + dScan;
        IF t >= %(tMez)s THEN estado := 3; END_IF
ELSE
        vLlenado := FALSE; motorMezcla := FALSE; vDescarga := TRUE;
        IF nivelBajo THEN estado := 0; END_IF
END_CASE"""


def i2(nombre, esperado, paso, tMez="T#60S", paroEnMezcla=True, paroApaga=True, salta=False, bloquea=False):
    sec = SECUENCIA_I2 % {"tras_llenado": "3" if salta else "2", "tMez": tMez}
    cond = "btnParo" if paroEnMezcla else "btnParo AND estado <> 2"
    apaga = "\n    vLlenado := FALSE; motorMezcla := FALSE; vDescarga := FALSE;" if paroApaga else ""
    extra_var = "\n    bloqueado : BOOL;" if bloquea else ""
    marca = "\n    bloqueado := TRUE;" if bloquea else ""
    if bloquea:
        sec = """
IF bloqueado THEN
    vLlenado := FALSE; motorMezcla := FALSE; vDescarga := FALSE;
ELSE""" + sec.replace("\n", "\n    ") + "\nEND_IF"
    cuerpo = DT_COD + """
IF %s THEN%s
    estado := 0;
    t := T#0S;%s
ELSE%s
END_IF""" % (cond, apaga, marca, sec.replace("\n", "\n    "))
    doble("I2", nombre, esperado, paso, fb("FB_Llenado", IO_I2, VAR_I2 + extra_var, cuerpo))


i2("Correcta", 1, None)
i2("MezclaCorta", 2, 3, tMez="T#30S")
i2("SaltaMezcla", 2, 2, salta=True)
i2("ParoNoSeguro", 2, 7, paroApaga=False)
i2("ParoSoloEnLlenado", 2, 10, paroEnMezcla=False)
i2("NoRearranca", 2, 8, bloquea=True)

# ============================================================== I3 FB_Alarmas
IO_I3 = """VAR_INPUT
    alm1 : BOOL;
    alm2 : BOOL;
    alm3 : BOOL;
    ack1 : BOOL;
    ack2 : BOOL;
    ack3 : BOOL;
END_VAR
VAR_OUTPUT
    sirena : BOOL;
    codigoAlm : INT;
END_VAR"""
VAR_I3 = "    lat : ARRAY[1..3] OF BOOL;\n    alm : ARRAY[1..3] OF BOOL;\n    ack : ARRAY[1..3] OF BOOL;\n    i : INT;"
ENTRADAS_I3 = """alm[1] := alm1; alm[2] := alm2; alm[3] := alm3;
ack[1] := ack1; ack[2] := ack2; ack[3] := ack3;"""
RETENCION = """
FOR i := 1 TO 3 DO
    IF alm[i] THEN
        lat[i] := TRUE;
    ELSIF ack[i] THEN
        lat[i] := FALSE;
    END_IF
END_FOR"""
SIRENA_LAT = "\nsirena := lat[1] OR lat[2] OR lat[3];"
CODIGO_ALTA = """
IF lat[1] THEN codigoAlm := 1; ELSIF lat[2] THEN codigoAlm := 2; ELSIF lat[3] THEN codigoAlm := 3; ELSE codigoAlm := 0; END_IF"""
doble("I3", "Correcta", 1, None, fb("FB_Alarmas", IO_I3, VAR_I3, ENTRADAS_I3 + RETENCION + SIRENA_LAT + CODIGO_ALTA))
doble("I3", "AckIncondicional", 2, 2, fb("FB_Alarmas", IO_I3, VAR_I3, ENTRADAS_I3 + """
FOR i := 1 TO 3 DO
    IF alm[i] THEN
        lat[i] := TRUE;
    END_IF
    IF ack[i] THEN
        lat[i] := FALSE;         (* borra sin comprobar la causa *)
    END_IF
END_FOR""" + SIRENA_LAT + CODIGO_ALTA))
doble("I3", "SinRetencion", 2, 3, fb("FB_Alarmas", IO_I3, VAR_I3, ENTRADAS_I3 + """
sirena := alm1 OR alm2 OR alm3;
IF alm1 THEN codigoAlm := 1; ELSIF alm2 THEN codigoAlm := 2; ELSIF alm3 THEN codigoAlm := 3; ELSE codigoAlm := 0; END_IF"""))
doble("I3", "PrioridadInvertida", 2, 6, fb("FB_Alarmas", IO_I3, VAR_I3, ENTRADAS_I3 + RETENCION + SIRENA_LAT + """
IF lat[3] THEN codigoAlm := 3; ELSIF lat[2] THEN codigoAlm := 2; ELSIF lat[1] THEN codigoAlm := 1; ELSE codigoAlm := 0; END_IF"""))
doble("I3", "SirenaSoloConCausa", 2, 3, fb("FB_Alarmas", IO_I3, VAR_I3, ENTRADAS_I3 + RETENCION + CODIGO_ALTA + """
sirena := alm1 OR alm2 OR alm3;"""))

# ============================================================== I4 FB_EstrellaTriangulo
IO_I4 = """VAR_INPUT
    btnMarcha : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    kM : BOOL;
    kY : BOOL;
    kD : BOOL;
END_VAR"""
VAR_I4 = "    estado : INT;\n    t1 : TON;\n    t2 : TON;"


def i4(nombre, esperado, paso, paro, rearma_reposo, est1, est2):
    reposo_timers = "\n        t1(IN := FALSE, PT := T#8S);\n        t2(IN := FALSE, PT := T#100MS);" if rearma_reposo else ""
    cuerpo = """
IF btnParo THEN
%s
    estado := 0;
ELSE
    CASE estado OF
        0:%s
            IF btnMarcha THEN
                kM := TRUE; kY := TRUE; estado := 1;
            END_IF
        1:
%s
        2:
%s
    END_CASE
END_IF""" % (paro, reposo_timers.replace("\n        ", "\n            "), est1, est2)
    doble("I4", nombre, esperado, paso, fb("FB_EstrellaTriangulo", IO_I4, VAR_I4, cuerpo))


PARO_OK = "    kM := FALSE; kY := FALSE; kD := FALSE;\n    t1(IN := FALSE, PT := T#8S);\n    t2(IN := FALSE, PT := T#100MS);"
E1_OK = "            t1(IN := TRUE, PT := T#8S);\n            IF t1.Q THEN kY := FALSE; estado := 2; END_IF"
E2_OK = "            t2(IN := TRUE, PT := T#100MS);\n            IF t2.Q THEN kD := TRUE; estado := 3; END_IF"
i4("Correcta", 1, None, PARO_OK, True, E1_OK, E2_OK)
i4("Solapamiento", 2, 3, PARO_OK, True,
   "            t1(IN := TRUE, PT := T#8S);\n            IF t1.Q THEN kD := TRUE; estado := 2; END_IF",
   "            t2(IN := TRUE, PT := T#40MS);\n            IF t2.Q THEN kY := FALSE; estado := 3; END_IF")
i4("SinTiempoMuerto", 2, 3, PARO_OK, True,
   "            t1(IN := TRUE, PT := T#8S);\n            IF t1.Q THEN kY := FALSE; kD := TRUE; estado := 2; END_IF",
   "            ;")
i4("TemporizadorSinRearme", 2, 5, "    kM := FALSE; kY := FALSE; kD := FALSE;", False, E1_OK, E2_OK)
i4("ParoNoApagaKM", 2, 4, "    kY := FALSE; kD := FALSE;\n    t1(IN := FALSE, PT := T#8S);\n    t2(IN := FALSE, PT := T#100MS);", True, E1_OK, E2_OK)

# ============================================================== I5 FB_Clasificadora
IO_I5 = """VAR_INPUT
    sensorPresencia : BOOL;
    sensorAltura : BOOL;
END_VAR
VAR_OUTPUT
    banda : BOOL;
    piston : BOOL;
    nAltas : INT;
    nBajas : INT;
END_VAR"""
VAR_I5 = DT_VAR + """
    prev : BOOL;
    detecta : BOOL;
    ev : ARRAY[0..19] OF TIME;
    activo : ARRAY[0..19] OF BOOL;
    i : INT;"""


def i5(nombre, esperado, paso, retardo="T#2S", pulso="T#1S", porNivel=False, desviaTodo=False):
    det = "sensorPresencia" if porNivel else "sensorPresencia AND NOT prev"
    desv = "sensorAltura OR TRUE" if desviaTodo else "sensorAltura"
    cuerpo = DT_COD + """
banda := TRUE;
detecta := %(det)s;
IF detecta THEN
    IF sensorAltura THEN nAltas := nAltas + 1; ELSE nBajas := nBajas + 1; END_IF
    IF %(desv)s THEN
        FOR i := 0 TO 19 DO
            IF NOT activo[i] THEN
                activo[i] := TRUE;
                ev[i] := T#0S;
                EXIT;
            END_IF
        END_FOR
    END_IF
END_IF
prev := sensorPresencia;
piston := FALSE;
FOR i := 0 TO 19 DO
    IF activo[i] THEN
        ev[i] := ev[i] + dScan;
        IF ev[i] >= %(r)s AND ev[i] < %(r)s + %(p)s THEN
            piston := TRUE;
        END_IF
        IF ev[i] >= %(r)s + %(p)s THEN
            activo[i] := FALSE;
        END_IF
    END_IF
END_FOR""" % {"det": det, "desv": desv, "r": retardo, "p": pulso}
    doble("I5", nombre, esperado, paso, fb("FB_Clasificadora", IO_I5, VAR_I5, cuerpo))


i5("Correcta", 1, None)
i5("CuentaPorNivel", 2, 1, porNivel=True)
i5("SinRetardo", 2, 3, retardo="T#0S")
i5("RetardoCorto", 2, 4, retardo="T#1500MS")
i5("PulsoLargo", 2, 6, pulso="T#2S")
i5("DesviaTodo", 2, 4, desviaTodo=True)

# ============================================================== I6 FB_Temperatura
IO_I6 = """VAR_INPUT
    rawTemp : INT;
END_VAR
VAR_OUTPUT
    tempC : REAL;
    enfriador : BOOL;
    almSensor : BOOL;
END_VAR"""


def i6(nombre, esperado, paso, fuera="rawTemp < 0 OR rawTemp > 27648", apaga_en_alarma=True,
       escalado="INT_TO_REAL(rawTemp) / 27648.0 * 100.0", histeresis=True, enclavada=False):
    apaga = "\n    enfriador := FALSE;" if apaga_en_alarma else ""
    if histeresis:
        control = """    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    END_IF"""
    else:
        control = "    enfriador := tempC >= 80.0;"
    pre = "almPrev := almSensor;\n" if enclavada else ""
    post = "\nalmSensor := almSensor OR almPrev;" if enclavada else ""
    cuerpo = pre + """IF %s THEN
    almSensor := TRUE;%s
ELSE
    almSensor := FALSE;
    tempC := %s;
%s
END_IF""" % (fuera, apaga, escalado, control) + post
    doble("I6", nombre, esperado, paso, fb("FB_Temperatura", IO_I6, "    almPrev : BOOL;", cuerpo))


i6("Correcta", 1, None)
i6("AlarmaNoApagaEnfriador", 2, 3, apaga_en_alarma=False)
i6("SinHisteresis", 2, 2, histeresis=False)
i6("DivisionEntera", 2, 0, escalado="INT_TO_REAL(rawTemp / 27648 * 100)")
i6("RangoSoloSuperior", 2, 6, fuera="rawTemp > 27648")
i6("AlarmaEnclavada", 2, 4, enclavada=True)

# ============================================================== escritura
manifiesto = []
contador = {}
for tarea, nombre, esperado, paso, texto in D:
    contador[tarea] = contador.get(tarea, 0) + 1
    rel = os.path.join(tarea, "%02d_%s.st" % (contador[tarea], nombre))
    ruta = os.path.join(AQUI, rel)
    if not os.path.isdir(os.path.dirname(ruta)):
        os.makedirs(os.path.dirname(ruta))
    with open(ruta, "w") as fh:
        fh.write(texto)
    manifiesto.append({"tarea": tarea, "doble": nombre, "archivo": rel.replace(os.sep, "/"),
                       "esperado": esperado, "paso_esperado": paso})
with open(os.path.join(AQUI, "manifiesto.json"), "w") as fh:
    json.dump(manifiesto, fh, indent=2)
print("%d dobles en %d tareas" % (len(D), len(contador)))
