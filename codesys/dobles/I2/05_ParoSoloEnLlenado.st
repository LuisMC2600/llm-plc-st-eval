(* DOBLE DE PRUEBA I2/ParoSoloEnLlenado - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 10 *)
FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto : BOOL;
    nivelBajo : BOOL;
    btnInicio : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    vLlenado : BOOL;
    motorMezcla : BOOL;
    vDescarga : BOOL;
END_VAR
VAR
    tAhora : TIME;
    tPrev : TIME;
    dScan : TIME;
    init : BOOL;
    estado : INT;
    t : TIME;
END_VAR
tAhora := TIME();
IF NOT init THEN
    tPrev := tAhora;
    init := TRUE;
END_IF
dScan := tAhora - tPrev;
tPrev := tAhora;
IF btnParo AND estado <> 2 THEN
    vLlenado := FALSE; motorMezcla := FALSE; vDescarga := FALSE;
    estado := 0;
    t := T#0S;
ELSE
    CASE estado OF
        0:
            vLlenado := FALSE; motorMezcla := FALSE; vDescarga := FALSE;
            IF btnInicio THEN estado := 1; END_IF
        1:
            vLlenado := TRUE; motorMezcla := FALSE; vDescarga := FALSE;
            IF nivelAlto THEN estado := 2; t := T#0S; END_IF
        2:
            vLlenado := FALSE; motorMezcla := TRUE; vDescarga := FALSE;
            t := t + dScan;
            IF t >= T#60S THEN estado := 3; END_IF
    ELSE
            vLlenado := FALSE; motorMezcla := FALSE; vDescarga := TRUE;
            IF nivelBajo THEN estado := 0; END_IF
    END_CASE
END_IF
END_FUNCTION_BLOCK
