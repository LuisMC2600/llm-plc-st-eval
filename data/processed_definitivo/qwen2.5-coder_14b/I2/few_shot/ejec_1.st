FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto : BOOL; (* Nivel alto detectado *)
    nivelBajo : BOOL; (* Nivel bajo detectado *)
    btnInicio : BOOL; (* Botón de inicio *)
    btnParo : BOOL; (* Botón de paro *)
END_VAR
VAR_OUTPUT
    vLlenado : BOOL; (* Válvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga : BOOL; (* Válvula de descarga *)
END_VAR
VAR
    estado : INT := 0; (* Estado actual del proceso *)
    tMezcla : TP; (* Temporizador para el motor de mezcla *)
END_VAR

(* Botón de paro detiene el proceso *)
IF btnParo THEN
    estado := 0;
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
END_IF

(* Máquina de estados *)
CASE estado OF
    0: (* Reposo *)
        IF btnInicio THEN
            estado := 1;
            vLlenado := TRUE;
        END_IF
    1: (* Llenado *)
        IF nivelAlto THEN
            estado := 2;
            vLlenado := FALSE;
            tMezcla(IN := TRUE, PT := T#60S);
            motorMezcla := TRUE;
        END_IF
    2: (* Mezcla *)
        IF tMezcla.Q THEN
            estado := 3;
            motorMezcla := FALSE;
            vDescarga := TRUE;
        END_IF
    3: (* Descarga *)
        IF nivelBajo THEN
            estado := 0;
            vDescarga := FALSE;
        END_IF
END_CASE
END_FUNCTION_BLOCK