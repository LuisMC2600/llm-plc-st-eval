```pascal
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

(* Lógica del proceso de llenado por etapas *)
IF btnParo THEN
    (* Si se presiona el botón de paro, detener todo y volver a reposo *)
    estado := 0;
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
ELSE
    CASE estado OF
        0: (* Estado de reposo *)
            IF btnInicio THEN
                estado := 1; (* Iniciar proceso de llenado *)
            END_IF;
        1: (* Llenado *)
            vLlenado := TRUE;
            IF nivelAlto THEN
                vLlenado := FALSE;
                estado := 2; (* Pasar al estado de mezcla *)
                tMezcla(IN := TRUE, PT := T#60S); (* Iniciar temporizador de mezcla *)
            END_IF;
        2: (* Mezcla *)
            motorMezcla := TRUE;
            IF tMezcla.Q THEN
                motorMezcla := FALSE;
                estado := 3; (* Pasar al estado de descarga *)
            END_IF;
        3: (* Descarga *)
            vDescarga := TRUE;
            IF nivelBajo THEN
                vDescarga := FALSE;
                estado := 0; (* Volver al estado de reposo *)
            END_IF;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK
```