(* DOBLE DE PRUEBA I1/NoReinicia - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 8 *)
FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL;
END_VAR
VAR_OUTPUT
    luzV : BOOL;
    luzA : BOOL;
    luzR : BOOL;
END_VAR
VAR
    tAhora : TIME;
    tPrev : TIME;
    dScan : TIME;
    init : BOOL;
    estado : INT;
    t : TIME;
    tParp : TIME;
    parp : BOOL;
    prevHab : BOOL;
END_VAR
tAhora := TIME();
IF NOT init THEN
    tPrev := tAhora;
    init := TRUE;
END_IF
dScan := tAhora - tPrev;
tPrev := tAhora;
IF NOT habilitado THEN
    luzV := FALSE;
    luzR := FALSE;
    tParp := tParp + dScan;
    IF tParp >= T#1S THEN
        tParp := T#0S;
        parp := NOT parp;
    END_IF
    luzA := parp;
    prevHab := FALSE;
ELSE
    prevHab := TRUE;
    t := t + dScan;
    CASE estado OF
        0:
            luzV := TRUE; luzA := FALSE; luzR := FALSE;
            IF t >= T#20S THEN estado := 1; t := T#0S; END_IF
        1:
            luzV := FALSE; luzA := TRUE; luzR := FALSE;
            IF t >= T#4S THEN estado := 2; t := T#0S; END_IF
    ELSE
            luzV := FALSE; luzA := FALSE; luzR := TRUE;
            IF t >= T#15S THEN estado := 0; t := T#0S; END_IF
    END_CASE
END_IF
END_FUNCTION_BLOCK
