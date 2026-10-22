FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto *)
    nivelBajo : BOOL; (* Sensor de nivel bajo *)
    btnInicio : BOOL; (* Botón de inicio del proceso *)
    btnParo : BOOL;   (* Botón de paro del proceso *)
END_VAR
VAR_OUTPUT
    vLlenado : BOOL;  (* Válvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga : BOOL; (* Válvula de descarga *)
END_VAR
VAR
    estado : INT := 0; (* Estado del proceso *)
    tMezcla : TON;     (* Temporizador para el motor de mezcla *)
END_VAR

(* Lógica de control del proceso de llenado por etapas *)
CASE estado OF
    0: (* Estado de reposo *)
        vLlenado := FALSE;
        motorMezcla := FALSE;
        vDescarga := FALSE;
        IF btnInicio THEN
            estado := 1; (* Iniciar llenado *)
        END_IF

    1: (* Estado de llenado *)
        vLlenado := TRUE;
        IF nivelAlto THEN
            vLlenado := FALSE;
            estado := 2; (* Iniciar mezcla *)
            tMezcla(IN := TRUE, PT := T#60S);
        END_IF

    2: (* Estado de mezcla *)
        motorMezcla := tMezcla.Q;
        IF NOT tMezcla.Q THEN
            estado := 3; (* Iniciar descarga *)
        END_IF

    3: (* Estado de descarga *)
        vDescarga := TRUE;
        IF nivelBajo THEN
            vDescarga := FALSE;
            estado := 0; (* Volver a reposo *)
        END_IF
END_CASE

(* Lógica de paro de emergencia *)
IF btnParo THEN
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    estado := 0; (* Volver a reposo *)
    tMezcla(IN := FALSE);
END_IF

END_FUNCTION_BLOCK