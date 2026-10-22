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

(* Estado 0: Reposo *)
IF btnInicio AND NOT btnParo AND estado = 0 THEN
    estado := 1;
    vLlenado := TRUE;
END_IF

(* Estado 1: Llenado *)
IF nivelAlto THEN
    estado := 2;
    vLlenado := FALSE;
    motorMezcla := TRUE;
    tMezcla(IN := TRUE, PT := T#60S);
END_IF

(* Estado 2: Mezcla *)
IF tMezcla.Q THEN
    estado := 3;
    motorMezcla := FALSE;
    vDescarga := TRUE;
END_IF

(* Estado 3: Descarga *)
IF nivelBajo THEN
    estado := 0;
    vDescarga := FALSE;
END_IF

(* Botón de paro *)
IF btnParo THEN
    estado := 0;
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    tMezcla(IN := FALSE);
END_IF

END_FUNCTION_BLOCK