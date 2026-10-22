FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto *)
    nivelBajo : BOOL; (* Sensor de nivel bajo *)
    btnInicio : BOOL; (* Botón de inicio *)
    btnParo : BOOL; (* Botón de paro *)
END_VAR
VAR_OUTPUT
    vLlenado : BOOL; (* Válvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga : BOOL; (* Válvula de descarga *)
END_VAR
VAR
    estado : INT := 0; (* Estado del proceso *)
    tMezcla : TON; (* Temporizador para mezcla *)
END_VAR

(* Control del proceso de llenado por etapas *)
CASE estado OF
    0: (* Estado de reposo *)
        vLlenado := FALSE;
        motorMezcla := FALSE;
        vDescarga := FALSE;
        IF btnInicio THEN
            estado := 1; (* Iniciar llenado *)
        END_IF;
    1: (* Estado de llenado *)
        vLlenado := TRUE;
        IF nivelAlto THEN
            vLlenado := FALSE;
            tMezcla(IN := TRUE, PT := T#60S);
            estado := 2; (* Iniciar mezcla *)
        END_IF;
    2: (* Estado de mezcla *)
        motorMezcla := tMezcla.Q;
        IF NOT tMezcla.Q THEN
            motorMezcla := FALSE;
            estado := 3; (* Iniciar descarga *)
        END_IF;
    3: (* Estado de descarga *)
        vDescarga := TRUE;
        IF nivelBajo THEN
            vDescarga := FALSE;
            estado := 0; (* Volver a reposo *)
        END_IF;
END_CASE;

(* Manejo del botón de paro *)
IF btnParo THEN
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    estado := 0; (* Volver a reposo *)
END_IF;
END_FUNCTION_BLOCK