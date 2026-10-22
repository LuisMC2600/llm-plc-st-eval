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

# ============================================================== B7 SelBomba (POU a eleccion)
# Tres correctas (una por tipo de POU) para verificar las tres variantes del harness.
IN_B7 = """VAR_INPUT
    modoAuto : BOOL;
    btnManual : BOOL;
    nivelBajo : BOOL;
END_VAR"""


def b7(nombre, esperado, paso, pou, cuerpo, var=""):
    if pou == "FUNCTION":
        texto = "FUNCTION SelBomba : BOOL\n%s\n%s%s\nEND_FUNCTION\n" % (
            IN_B7, ("VAR\n%s\nEND_VAR\n" % var) if var else "", cuerpo.replace("bomba :=", "SelBomba :="))
    else:
        texto = "%s SelBomba\n%s\nVAR_OUTPUT\n    bomba : BOOL;\nEND_VAR\nVAR\n%s\nEND_VAR\n%s\nEND_%s\n" % (
            pou, IN_B7, var or "    nada : BOOL;", cuerpo, pou)
    doble("B7", nombre, esperado, paso, texto)


SEL_OK = """IF modoAuto THEN
    bomba := nivelBajo;
ELSE
    bomba := btnManual;
END_IF"""
b7("Correcta", 1, None, "FUNCTION", SEL_OK)
b7("CorrectaFB", 1, None, "FUNCTION_BLOCK", SEL_OK)
b7("CorrectaPRG", 1, None, "PROGRAM", SEL_OK)
b7("ModoInvertido", 2, 1, "FUNCTION", """IF modoAuto THEN
    bomba := btnManual;
ELSE
    bomba := nivelBajo;
END_IF""")
b7("OrSimple", 2, 3, "FUNCTION", "bomba := btnManual OR nivelBajo;")
b7("NivelInvertido", 2, 4, "FUNCTION", """IF modoAuto THEN
    bomba := NOT nivelBajo;
ELSE
    bomba := btnManual;
END_IF""")
b7("BotonTambienEnAuto", 2, 6, "FUNCTION", """IF modoAuto THEN
    bomba := nivelBajo OR btnManual;
ELSE
    bomba := btnManual;
END_IF""")
b7("MemoriaEnAuto", 2, 5, "FUNCTION_BLOCK", """IF modoAuto THEN
    bomba := bomba OR nivelBajo;
ELSE
    bomba := btnManual;
END_IF""")
b7("TelerruptorManual", 2, 2, "PROGRAM", """IF modoAuto THEN
    bomba := nivelBajo;
ELSIF btnManual AND NOT prev THEN
    bomba := NOT bomba;
END_IF
prev := btnManual;""", var="    prev : BOOL;")

# ============================================================== B8 FB_Puerta
IO_B8 = """VAR_INPUT
    puertaAbierta : BOOL;
    reset : BOOL;
END_VAR
VAR_OUTPUT
    aviso : BOOL;
    nAperturas : INT;
END_VAR"""


def b8(nombre, esperado, paso, cuenta="puertaAbierta AND NOT prev", aviso="aviso := nAperturas >= 5;",
       reset="nAperturas := 0;", satura=False):
    cond = cuenta + (" AND nAperturas < 5" if satura else "")
    cuerpo = """IF reset THEN
    %s
ELSIF %s THEN
    nAperturas := nAperturas + 1;
END_IF
prev := puertaAbierta;
%s""" % (reset, cond, aviso)
    doble("B8", nombre, esperado, paso, fb("FB_Puerta", IO_B8, "    prev : BOOL;", cuerpo))


b8("Correcta", 1, None)
b8("CuentaPorNivel", 2, 1, cuenta="puertaAbierta")
b8("CuentaFlancoBajada", 2, 1, cuenta="prev AND NOT puertaAbierta")
b8("UmbralCuatro", 2, 4, aviso="aviso := nAperturas >= 4;")
b8("UmbralSeis", 2, 5, aviso="aviso := nAperturas > 5;")
b8("AvisoSoloEnCinco", 2, 6, aviso="aviso := nAperturas = 5;")
b8("SaturaEnCinco", 2, 6, satura=True)
b8("ResetNoApagaAviso", 2, 7, aviso="aviso := aviso OR nAperturas >= 5;")
b8("ResetSoloAviso", 2, 7, reset="aviso := FALSE;", aviso="IF NOT reset THEN\n    aviso := nAperturas >= 5;\nEND_IF")

# ============================================================== I7 FB_Duplex
IO_I7 = """VAR_INPUT
    demanda : BOOL;
    falla1 : BOOL;
    falla2 : BOOL;
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;
    bomba2 : BOOL;
    almFalla : BOOL;
END_VAR"""
VAR_I7 = "    turno : BOOL;\n    fDem : R_TRIG;"
# Logica correcta dada la principal; los defectos alteran una parte concreta.
SAL_I7 = """IF demanda THEN
    IF turno THEN
        bomba1 := NOT falla1;
        bomba2 := falla1 AND NOT falla2;
        almFalla := falla1;
    ELSE
        bomba2 := NOT falla2;
        bomba1 := falla2 AND NOT falla1;
        almFalla := falla2;
    END_IF
ELSE
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF"""
ALT_I7 = "fDem(CLK := demanda);\nIF fDem.Q THEN\n    turno := NOT turno;\nEND_IF\n"


def i7(nombre, esperado, paso, cuerpo, var=VAR_I7):
    doble("I7", nombre, esperado, paso, fb("FB_Duplex", IO_I7, var, cuerpo))


i7("Correcta", 1, None, ALT_I7 + SAL_I7)
# El FB del prompt de C4 (FB_D), renombrado: debe superar el harness de I7 (decision D5).
i7("ReferenciaC4", 1, None, ALT_I7 + SAL_I7)
i7("SinAlternancia", 2, 3, "fDem(CLK := demanda);\nturno := TRUE;\n" + SAL_I7)
i7("PrimeraEsB2", 2, 1, ALT_I7 + SAL_I7.replace("IF turno THEN", "IF NOT turno THEN"))
i7("AmbasArrancan", 2, 1, ALT_I7 + SAL_I7 + """
IF demanda THEN
    bomba1 := NOT falla1;
    bomba2 := NOT falla2;
END_IF""")
i7("SinRespaldo", 2, 6, ALT_I7 + SAL_I7 + """
IF turno THEN
    bomba2 := FALSE;
ELSE
    bomba1 := FALSE;
END_IF""")
i7("RespaldoEnclavado", 2, 7, ALT_I7 + """IF NOT demanda THEN
    enResp := FALSE;
ELSIF (turno AND falla1) OR (NOT turno AND falla2) THEN
    enResp := TRUE;
END_IF
IF NOT demanda THEN
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
ELSIF enResp THEN
    IF turno THEN
        bomba1 := FALSE;
        bomba2 := NOT falla2;
        almFalla := falla1;
    ELSE
        bomba2 := FALSE;
        bomba1 := NOT falla1;
        almFalla := falla2;
    END_IF
ELSE
""" + "\n".join("    " + l for l in SAL_I7.splitlines()[1:-5]) + """
END_IF""", var=VAR_I7 + "\n    enResp : BOOL;")
i7("AlarmaPorRespaldo", 2, 8, ALT_I7 + SAL_I7 + "\nalmFalla := demanda AND (falla1 OR falla2);")
i7("RespaldoConFalla", 2, 9, ALT_I7 + SAL_I7 + """
IF demanda THEN
    IF turno THEN
        bomba2 := falla1;
    ELSE
        bomba1 := falla2;
    END_IF
END_IF""")
i7("AlarmaSinDemanda", 2, 10, ALT_I7 + SAL_I7 + """
IF turno THEN
    almFalla := falla1;
ELSE
    almFalla := falla2;
END_IF""")

# ============================================================== I8 FB_Compresor
IO_I8 = """VAR_INPUT
    pOilOk : BOOL;
    tempOk : BOOL;
    sinAlm : BOOL;
    btnMarcha : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    comp : BOOL;
    causaBloqueo : INT;
END_VAR"""
VAR_I8 = "    tOil : TON;\n    fMarcha : R_TRIG;\n    oil : BOOL;\n    perm : BOOL;\n    lat : BOOL;\n    pet : BOOL;"
ACEITE_OK = "tOil(IN := pOilOk, PT := T#3S);\noil := tOil.Q;"
CAUSA_OK = """IF NOT oil THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF
perm := causaBloqueo = 0;
fMarcha(CLK := btnMarcha);"""
LOGICA_OK = """IF btnParo OR NOT perm THEN
    comp := FALSE;
ELSIF fMarcha.Q THEN
    comp := TRUE;
END_IF"""


def i8(nombre, esperado, paso, aceite=ACEITE_OK, causa=CAUSA_OK, logica=LOGICA_OK):
    doble("I8", nombre, esperado, paso, fb("FB_Compresor", IO_I8, VAR_I8, "\n".join([aceite, causa, logica])))


i8("Correcta", 1, None)
i8("SinTemporizacionAceite", 2, 1, aceite="oil := pOilOk;")
i8("RearranqueAutomatico", 2, 6, logica="""lat := (lat OR fMarcha.Q) AND NOT btnParo;
comp := lat AND perm;""")
i8("MarchaPrioritaria", 2, 7, logica="""IF fMarcha.Q AND perm THEN
    comp := TRUE;
ELSIF btnParo OR NOT perm THEN
    comp := FALSE;
END_IF""")
i8("ArrancaPorNivel", 2, 8, logica="comp := (comp OR btnMarcha) AND perm AND NOT btnParo;")
i8("CausaPrioridadInvertida", 2, 0, causa=CAUSA_OK.replace("""IF NOT oil THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;""", """IF NOT sinAlm THEN
    causaBloqueo := 3;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT oil THEN
    causaBloqueo := 1;"""))
i8("AceiteNoContinuo", 2, 12, aceite="tOil(IN := pOilOk, PT := T#3S);\noil := oil OR tOil.Q;")
i8("PeticionMemorizada", 2, 14, logica="""pet := (pet OR fMarcha.Q) AND NOT btnParo;
IF btnParo OR (comp AND NOT perm) THEN
    comp := FALSE;
    pet := FALSE;
ELSIF pet AND perm THEN
    comp := TRUE;
END_IF""")

# ============================================================== C3 PRG_Conversion (PROGRAM)
def c3(nombre, esperado, paso, rama1="motor := (btnMarcha OR motor) AND NOT btnParo;",
       rama2="T1(IN := motor, PT := T#10S);\nlampara := T1.Q;", var_local=False):
    if var_local:
        decl = "VAR\n    btnMarcha : BOOL;\n    btnParo : BOOL;\n    motor : BOOL;\n    lampara : BOOL;\n    T1 : TON;\nEND_VAR"
    else:
        decl = ("VAR_INPUT\n    btnMarcha : BOOL;\n    btnParo : BOOL;\nEND_VAR\n"
                "VAR_OUTPUT\n    motor : BOOL;\n    lampara : BOOL;\nEND_VAR\nVAR\n    T1 : TON;\nEND_VAR")
    doble("C3", nombre, esperado, paso,
          "PROGRAM PRG_Conversion\n%s\n%s\n%s\nEND_PROGRAM\n" % (decl, rama1, rama2))


c3("Correcta", 1, None)
c3("ParoComoNA", 2, 1, rama1="motor := (btnMarcha OR motor) AND btnParo;")
c3("SinEnclavamiento", 2, 2, rama1="motor := btnMarcha AND NOT btnParo;")
c3("MarchaPrioritaria", 2, 6, rama1="motor := btnMarcha OR (motor AND NOT btnParo);")
c3("LamparaSinTemporizar", 2, 1, rama2="T1(IN := motor, PT := T#10S);\nlampara := motor;")
c3("TiempoCinco", 2, 2, rama2="T1(IN := motor, PT := T#5S);\nlampara := T1.Q;")
c3("TemporizadorRetenido", 2, 4, rama2="T1(IN := motor OR T1.Q, PT := T#10S);\nlampara := T1.Q;")

# ============================================================== A3 FB_Com
IO_A3 = """VAR_INPUT
    txReq : BOOL;
    rxOk : BOOL;
    rxData : INT;
END_VAR
VAR_OUTPUT
    txData : INT;
    ocupado : BOOL;
    ok : BOOL;
    error : BOOL;
    nIntentos : INT;
END_VAR"""


def a3(nombre, esperado, paso, pt="T#500MS", eco="rxOk AND rxData = txData", maximo=3,
       ignora_tx=True, reinicia_plazo=True, borra_resultado=True, conserva_n=True):
    inicio = "flanco AND NOT ocupado" if ignora_tx else "flanco"
    borrar = "    ok := FALSE;\n    error := FALSE;\n" if borra_resultado else ""
    reinicio = "            tPlazo(IN := FALSE, PT := %s);\n" % pt if reinicia_plazo else ""
    final = "" if conserva_n else "\nIF NOT ocupado THEN\n    nIntentos := 0;\nEND_IF"
    cuerpo = """flanco := txReq AND NOT prev;
prev := txReq;
IF %s THEN
    txData := 100;
    ocupado := TRUE;
%s    nIntentos := 1;
    tPlazo(IN := FALSE, PT := %s);
ELSIF ocupado THEN
    tPlazo(IN := TRUE, PT := %s);
    IF %s THEN
        ok := TRUE;
        ocupado := FALSE;
    ELSIF rxOk OR tPlazo.Q THEN
        IF nIntentos < %d THEN
            nIntentos := nIntentos + 1;
%s        ELSE
            error := TRUE;
            ocupado := FALSE;
        END_IF
    END_IF
END_IF%s""" % (inicio, borrar, pt, pt, eco, maximo, reinicio, final)
    doble("A3", nombre, esperado, paso, fb("FB_Com", IO_A3, "    tPlazo : TON;\n    prev : BOOL;\n    flanco : BOOL;", cuerpo))


a3("Correcta", 1, None)
a3("PlazoCorto", 2, 2, pt="T#300MS")
a3("PlazoLargo", 2, 3, pt="T#1S")
a3("PlazoNoSeReinicia", 2, 3, reinicia_plazo=False)
a3("IntentosSeBorran", 2, 4, conserva_n=False)
a3("OkNoSeBorra", 2, 6, borra_resultado=False)
a3("SinEco", 2, 7, eco="rxOk")
a3("ReiniciaPorTxReq", 2, 8, ignora_tx=False)
a3("CuatroIntentos", 2, 10, maximo=4)

# ============================================================== A2 FB_Batch
IO_A2 = """VAR_INPUT
    nivelA : BOOL;
    nivelB : BOOL;
    nivelVacio : BOOL;
    btnInicio : BOOL;
    btnAbort : BOOL;
    temp : REAL;
END_VAR
VAR_OUTPUT
    vA : BOOL;
    vB : BOOL;
    calentador : BOOL;
    mezclador : BOOL;
    vDescarga : BOOL;
    fase : INT;
END_VAR"""


def a2(nombre, esperado, paso, inicio="btnInicio AND fase = 0", abort_destino="IF nivelVacio THEN\n        fase := 0;\n    ELSE\n        fase := 5;\n    END_IF",
       umbral="temp >= 60.0", t_mez="T#120S", previo="", abort_extra="", cal_extra=""):
    cuerpo = """%sIF %s THEN
    fase := 1;
ELSIF btnAbort AND fase >= 1 AND fase <= 4 THEN
%s    %s
ELSE
    CASE fase OF
        1: IF nivelA THEN fase := 2; END_IF
        2: IF nivelB THEN fase := 3; END_IF
        3: IF %s THEN fase := 4; END_IF
        4: IF tMez.Q THEN fase := 5; END_IF
        5: IF nivelVacio THEN fase := 0; END_IF
    END_CASE
END_IF
tMez(IN := fase = 4, PT := %s);
vA := fase = 1;
vB := fase = 2;
calentador := fase = 3;
mezclador := fase = 4;
vDescarga := fase = 5;%s""" % (previo, inicio, abort_extra, abort_destino, umbral, t_mez, cal_extra)
    doble("A2", nombre, esperado, paso, fb("FB_Batch", IO_A2, "    tMez : TON;\n    calLat : BOOL;", cuerpo))


a2("Correcta", 1, None)
a2("AbortEnReposo", 2, 1, previo="IF btnAbort AND fase = 0 AND NOT nivelVacio THEN\n    fase := 5;\nELS")
a2("InicioNoIgnorado", 2, 5, inicio="btnInicio")
a2("UmbralEstricto", 2, 8, umbral="temp > 60.0")
a2("MezclaCorta", 2, 9, t_mez="T#60S")
a2("MezclaLarga", 2, 10, t_mez="T#180S")
a2("AbortSiempreReposo", 2, 13, abort_destino="fase := 0;")
a2("AbortNoCierraCalentador", 2, 21, abort_extra="    IF fase = 3 THEN\n        calLat := TRUE;\n    END_IF\n",
   cal_extra="\nIF fase = 0 THEN\n    calLat := FALSE;\nEND_IF\ncalentador := calentador OR calLat;")
a2("AbortEnDescargaDetiene", 2, 13, previo="IF btnAbort AND fase = 5 THEN\n    fase := 0;\nELS")

# ============================================================== A4 FB_Rampa
IO_A4 = """VAR_INPUT
    SPvel : REAL;
    paroRapido : BOOL;
    ciclo : TIME;
END_VAR
VAR_OUTPUT
    CVvel : REAL;
END_VAR"""
VAR_A4 = "    d : REAL;\n    obj : REAL;\n    bajada : REAL;\n    llego : BOOL;"


def a4(nombre, esperado, paso, sub="10.0", baj="20.0", paro="40.0", d="TIME_TO_REAL(ciclo) / 1000.0",
       acota=True, previo="", post=""):
    if acota:
        mover = """IF CVvel < obj THEN
    CVvel := MIN(obj, CVvel + %s * d);
ELSIF CVvel > obj THEN
    CVvel := MAX(obj, CVvel - bajada * d);
END_IF""" % sub
    else:
        mover = """IF CVvel < obj THEN
    CVvel := CVvel + %s * d;
ELSIF CVvel > obj THEN
    CVvel := CVvel - bajada * d;
END_IF""" % sub
    cuerpo = """d := %s;
IF paroRapido THEN
    obj := 0.0;
    bajada := %s;
ELSE
    obj := SPvel;
    bajada := %s;
END_IF
%s%s%s""" % (d, paro, baj, previo, mover, post)
    doble("A4", nombre, esperado, paso, fb("FB_Rampa", IO_A4, VAR_A4, cuerpo))


a4("Correcta", 1, None)
a4("SubidaRapida", 2, 2, sub="20.0")
a4("BajadaLenta", 2, 4, baj="10.0")
a4("ParoLento", 2, 7, paro="20.0")
a4("ParoInstantaneo", 2, 7, previo="IF paroRapido THEN\n    CVvel := 0.0;\nEND_IF\n")
a4("ParoNoMantiene", 2, 8, previo="""IF NOT paroRapido THEN
    llego := FALSE;
END_IF
IF paroRapido AND llego THEN
    obj := SPvel;
    bajada := 20.0;
END_IF
""", post="""
IF paroRapido AND CVvel <= 0.0 THEN
    llego := TRUE;
END_IF""")
a4("Sobrepaso", 2, 0, acota=False)
a4("CicloEnMs", 2, 2, d="TIME_TO_REAL(ciclo)")

# ============================================================== A5 FB_Registro
TIPO_A5 = """TYPE ST_Evento :
STRUCT
    codigo : INT;
    marca : TIME;
END_STRUCT
END_TYPE

"""
IO_A5 = """VAR_INPUT
    evento : INT;
    nuevoEvento : BOOL;
    ciclo : TIME;
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento;
    indice : INT := -1;
    nEventos : INT;
END_VAR"""


def a5(nombre, esperado, paso, acum_antes=True, flanco="nuevoEvento AND NOT prev",
       siguiente="(indice + 1) MOD 20", marca="tAcum", registrar_si="TRUE", n_expr="MIN(20, nEventos + 1)",
       io=IO_A5, extra_var="", extra_reg=""):
    acum = "tAcum := tAcum + ciclo;\n"
    cuerpo = """%sIF (%s) AND (%s) THEN
    indice := %s;
    buffer[indice].codigo := evento;
    buffer[indice].marca := %s;
    nEventos := %s;%s
END_IF
prev := nuevoEvento;
%s""" % (acum if acum_antes else "", flanco, registrar_si, siguiente, marca, n_expr, extra_reg, "" if acum_antes else acum)
    doble("A5", nombre, esperado, paso,
          TIPO_A5 + fb("FB_Registro", io, "    tAcum : TIME;\n    prev : BOOL;\n    nTotal : INT;" + extra_var, cuerpo))


a5("Correcta", 1, None)
a5("CorrectaAcumDespues", 1, None, acum_antes=False)
a5("IndiceInicialCero", 2, 0, io=IO_A5.replace("indice : INT := -1;", "indice : INT;"),
   siguiente="SEL(vacio, (indice + 1) MOD 20, 0)", extra_var="\n    vacio : BOOL := TRUE;",
   extra_reg="\n    vacio := FALSE;")
a5("CuentaPorNivel", 2, 1, flanco="nuevoEvento")
a5("MarcaSinAcumular", 2, 1, marca="ciclo")
a5("PrimeroEnPosicion1", 2, 0, io=IO_A5.replace("indice : INT := -1;", "indice : INT;"))
a5("SinSobrescritura", 2, 4, registrar_si="nEventos < 20")
a5("NEventosSinTope", 2, 4, n_expr="nEventos + 1")
a5("VueltaAPosicion1", 2, 4, siguiente="SEL(indice < 19, 1, indice + 1)")

# ============================================================== A6 FB_Modos
IO_A6 = """VAR_INPUT
    selector : INT;
    estadoSeguro : BOOL;
    cmdAuto : ARRAY[0..7] OF BOOL;
    cmdManual : ARRAY[0..7] OF BOOL;
    idxForzado : INT;
    valorForzado : BOOL;
    confirmarForzado : BOOL;
END_VAR
VAR_OUTPUT
    modoActivo : INT := @INI@;
    actuador : ARRAY[0..7] OF BOOL;
END_VAR"""
LIMPIA_A6 = "FOR i := 0 TO 7 DO\n        forz[i] := FALSE;\n    END_FOR"


def a6(nombre, esperado, paso, ini=1, cond="estadoSeguro AND selector >= 0 AND selector <= 2 AND selector <> modoActivo",
       al_salir=True, previo="", post_cambio="", seguro_anula=True,
       forzar="flanco AND idxForzado >= 0 AND idxForzado <= 7", destino="forz[idxForzado]",
       mant="actuador[i] := forz[i];", post_mant=""):
    salir = ("    IF modoActivo = 2 THEN\n        %s\n    END_IF\n" % LIMPIA_A6) if al_salir else ""
    anula = ("IF NOT estadoSeguro THEN\n        %s\n    ELS" % LIMPIA_A6) if seguro_anula else ""
    cuerpo = """%sIF %s THEN
%s    modoActivo := selector;
END_IF
%sflanco := confirmarForzado AND NOT prev;
prev := confirmarForzado;
CASE modoActivo OF
    0:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR
    1:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR
ELSE
    %sIF %s THEN
        %s := valorForzado;
    END_IF
    FOR i := 0 TO 7 DO
        %s
    END_FOR%s
END_CASE""" % (previo, cond, salir, post_cambio, anula, forzar, destino, mant, post_mant)
    doble("A6", nombre, esperado, paso, fb("FB_Modos", IO_A6.replace("@INI@", str(ini)),
          "    forz : ARRAY[0..7] OF BOOL;\n    prev : BOOL;\n    flanco : BOOL;\n    i : INT;\n    selPrev : INT := 1;", cuerpo))


a6("Correcta", 1, None)
a6("ArrancaEnAuto", 2, 0, ini=0)
a6("CambioSinSeguro", 2, 0, cond="selector >= 0 AND selector <= 2 AND selector <> modoActivo")
a6("CambioSoloPorFlancoDeSelector", 2, 2,
   cond="selector <> selPrev AND estadoSeguro AND selector >= 0 AND selector <= 2 AND selector <> modoActivo",
   post_cambio="selPrev := selector;\n")
a6("AceptaFueraDeRango", 2, 3, cond="estadoSeguro AND selector <> modoActivo")
a6("MantenimientoSigueManual", 2, 6, mant="actuador[i] := forz[i] OR cmdManual[i];")
a6("ForzadoNoRetiene", 2, 7, post_mant="""
    IF NOT (flanco AND idxForzado >= 0 AND idxForzado <= 7) THEN
        %s
    END_IF""" % LIMPIA_A6)
a6("IdxSinValidar", 2, 8, forzar="flanco", destino="forz[LIMIT(0, idxForzado, 7)]")
a6("SeguroNoAnula", 2, 11, seguro_anula=False)
a6("SalirNoAnula", 2, 15, al_salir=False)

# ============================================================== A1 FB_PID
IO_A1 = """VAR_INPUT
    SP : REAL;
    PV : REAL;
    Kp : REAL;
    Ti : REAL;
    Td : REAL;
    ciclo : TIME;
END_VAR
VAR_OUTPUT
    CV : REAL;
END_VAR"""
VAR_A1 = "    I : REAL;\n    ePrev : REAL;\n    pvPrev : REAL;\n    e : REAL;\n    d : REAL;\n    dt : REAL;\n    cv0 : REAL;\n    eAnt : REAL;\n    primero : BOOL := TRUE;"
PID_OK = """dt := TIME_TO_REAL(ciclo) / 1000.0;
e := SP - PV;
IF primero THEN
    ePrev := e;
    pvPrev := PV;
    primero := FALSE;
END_IF
d := (e - ePrev) / dt;
ePrev := e;
pvPrev := PV;
IF Ti > 0.0 THEN
    IF NOT ((CV >= 100.0 AND e > 0.0) OR (CV <= 0.0 AND e < 0.0)) THEN
        I := I + e * dt;
    END_IF
    cv0 := Kp * (e + I / Ti + Td * d);
ELSE
    cv0 := Kp * (e + Td * d);
END_IF
CV := LIMIT(0.0, cv0, 100.0);"""


def a1(nombre, esperado, paso, cuerpo=PID_OK, reemplazos=()):
    for a, b in reemplazos:
        assert a in cuerpo, (nombre, a)
        cuerpo = cuerpo.replace(a, b)
    # 'DT' es palabra reservada IEC (DATE_AND_TIME): CODESYS la rechaza como
    # identificador (leccion del 30-09-2026, repetida el 01-10-2026 en A1).
    import re
    cuerpo = re.sub(r"\bdt\b", "tMuestreo", cuerpo)
    doble("A1", nombre, esperado, paso, fb("FB_PID", IO_A1, VAR_A1.replace("    dt : REAL;", "    tMuestreo : REAL;"), cuerpo))


a1("Correcta", 1, None)
a1("CorrectaIntegralPrevia", 1, None, cuerpo="""dt := TIME_TO_REAL(ciclo) / 1000.0;
e := SP - PV;
d := (e - ePrev) / dt;
ePrev := e;
IF Ti > 0.0 THEN
    cv0 := Kp * (e + I / Ti + Td * d);
    IF NOT ((cv0 >= 100.0 AND e > 0.0) OR (cv0 <= 0.0 AND e < 0.0)) THEN
        I := I + e * dt;
    END_IF
ELSE
    cv0 := Kp * (e + Td * d);
END_IF
CV := LIMIT(0.0, cv0, 100.0);""")
a1("CorrectaTrapezoidal", 1, None, reemplazos=(("d := (e - ePrev) / dt;\nePrev := e;", "d := (e - ePrev) / dt;\neAnt := ePrev;\nePrev := e;"),
                                             ("I := I + e * dt;", "I := I + 0.5 * (e + eAnt) * dt;")))
a1("SignoInvertido", 2, 0, reemplazos=(("e := SP - PV;", "e := PV - SP;"),))
a1("SinSaturacion", 2, 1, reemplazos=(("CV := LIMIT(0.0, cv0, 100.0);", "CV := cv0;"),))
a1("TiCeroIntegra", 2, 0, reemplazos=(("""ELSE
    cv0 := Kp * (e + Td * d);
END_IF""", """ELSE
    I := I + e * dt;
    cv0 := Kp * (e + I + Td * d);
END_IF"""),))
a1("IntegralSinDt", 2, 4, reemplazos=(("I := I + e * dt;", "I := I + e;"),))
a1("CicloEnMs", 2, 4, reemplazos=(("dt := TIME_TO_REAL(ciclo) / 1000.0;", "dt := TIME_TO_REAL(ciclo);"),))
a1("SinDerivada", 2, 6, reemplazos=(("Td * d", "0.0 * d"),))
a1("DerivadaSobrePV", 2, 6, reemplazos=(("d := (e - ePrev) / dt;", "d := -(PV - pvPrev) / dt;"),))
a1("SinAntiWindup", 2, 8, reemplazos=(("IF NOT ((CV >= 100.0 AND e > 0.0) OR (CV <= 0.0 AND e < 0.0)) THEN", "IF TRUE THEN"),))
a1("AntiWindupSoloAlto", 2, 10, reemplazos=(("IF NOT ((CV >= 100.0 AND e > 0.0) OR (CV <= 0.0 AND e < 0.0)) THEN", "IF NOT (CV >= 100.0 AND e > 0.0) THEN"),))

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
