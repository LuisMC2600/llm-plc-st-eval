(* DOBLE DE PRUEBA A2/MezclaCorta - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 9 *)
FUNCTION_BLOCK FB_Batch
VAR_INPUT
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
END_VAR
VAR
    tMez : TON;
    calLat : BOOL;
END_VAR
IF btnInicio AND fase = 0 THEN
    fase := 1;
ELSIF btnAbort AND fase >= 1 AND fase <= 4 THEN
    IF nivelVacio THEN
        fase := 0;
    ELSE
        fase := 5;
    END_IF
ELSE
    CASE fase OF
        1: IF nivelA THEN fase := 2; END_IF
        2: IF nivelB THEN fase := 3; END_IF
        3: IF temp >= 60.0 THEN fase := 4; END_IF
        4: IF tMez.Q THEN fase := 5; END_IF
        5: IF nivelVacio THEN fase := 0; END_IF
    END_CASE
END_IF
tMez(IN := fase = 4, PT := T#60S);
vA := fase = 1;
vB := fase = 2;
calentador := fase = 3;
mezclador := fase = 4;
vDescarga := fase = 5;
END_FUNCTION_BLOCK
