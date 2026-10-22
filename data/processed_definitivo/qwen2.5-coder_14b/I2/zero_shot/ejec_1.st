FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto, nivelBajo, btnInicio, btnParo : BOOL;
END_VAR

VAR_OUTPUT
    vLlenado, motorMezcla, vDescarga : BOOL;
END_VAR

VAR
    estado : INT := 0; // 0: reposo, 1: llenado, 2: mezcla, 3: descarga
    timerMezcla : TON;
END_VAR

// Estado de reposo
IF btnParo THEN
    estado := 0;
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    timerMezcla(IN := FALSE);
ELSIF btnInicio AND estado = 0 THEN
    estado := 1;
    vLlenado := TRUE;
END_IF

// Estado de llenado
IF estado = 1 THEN
    IF nivelAlto THEN
        estado := 2;
        vLlenado := FALSE;
        motorMezcla := TRUE;
        timerMezcla(IN := TRUE, PT := T#60S);
    END_IF
END_IF

// Estado de mezcla
IF estado = 2 THEN
    IF timerMezcla.Q THEN
        estado := 3;
        motorMezcla := FALSE;
        vDescarga := TRUE;
    END_IF
END_IF

// Estado de descarga
IF estado = 3 THEN
    IF nivelBajo THEN
        estado := 0;
        vDescarga := FALSE;
    END_IF
END_IF