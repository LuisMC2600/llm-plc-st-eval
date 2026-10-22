(* DOBLE DE PRUEBA I5/Correcta - NO ES CORPUS. Esperado: veredicto 1 *)
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL;
    sensorAltura : BOOL;
END_VAR
VAR_OUTPUT
    banda : BOOL;
    piston : BOOL;
    nAltas : INT;
    nBajas : INT;
END_VAR
VAR
    tAhora : TIME;
    tPrev : TIME;
    dScan : TIME;
    init : BOOL;
    prev : BOOL;
    detecta : BOOL;
    ev : ARRAY[0..19] OF TIME;
    activo : ARRAY[0..19] OF BOOL;
    i : INT;
END_VAR
tAhora := TIME();
IF NOT init THEN
    tPrev := tAhora;
    init := TRUE;
END_IF
dScan := tAhora - tPrev;
tPrev := tAhora;
banda := TRUE;
detecta := sensorPresencia AND NOT prev;
IF detecta THEN
    IF sensorAltura THEN nAltas := nAltas + 1; ELSE nBajas := nBajas + 1; END_IF
    IF sensorAltura THEN
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
        IF ev[i] >= T#2S AND ev[i] < T#2S + T#1S THEN
            piston := TRUE;
        END_IF
        IF ev[i] >= T#2S + T#1S THEN
            activo[i] := FALSE;
        END_IF
    END_IF
END_FOR
END_FUNCTION_BLOCK
