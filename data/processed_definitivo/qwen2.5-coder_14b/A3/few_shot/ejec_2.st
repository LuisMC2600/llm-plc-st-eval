FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL; (* Petición de transmisión *)
    rxOk : BOOL; (* Confirmación de recepción *)
    rxData : INT; (* Datos recibidos *)
END_VAR
VAR_OUTPUT
    txData : INT; (* Datos a transmitir *)
    ocupado : BOOL; (* Estado de ocupado *)
    ok : BOOL; (* Confirmación de éxito *)
    error : BOOL; (* Confirmación de error *)
    nIntentos : INT; (* Número de intentos *)
END_VAR
VAR
    tEspera : TP; (* Temporizador de espera *)
    estado : INT; (* Estado actual del intercambio *)
    intentos : INT; (* Contador de intentos *)
END_VAR

(* Estados: 0 = Inactivo, 1 = En espera de respuesta, 2 = Éxito, 3 = Error *)
IF txReq AND NOT ocupado THEN
    estado := 1;
    intentos := 1;
    txData := 100;
    ocupado := TRUE;
    tEspera(IN := TRUE, PT := T#500MS);
END_IF

CASE estado OF
    1: (* Esperando respuesta *)
        IF tEspera.Q THEN
            IF rxOk AND rxData = txData THEN
                estado := 2;
                ok := TRUE;
                ocupado := FALSE;
            ELSE
                intentos := intentos + 1;
                IF intentos > 3 THEN
                    estado := 3;
                    error := TRUE;
                    ocupado := FALSE;
                ELSE
                    tEspera(IN := TRUE, PT := T#500MS);
                END_IF;
            END_IF;
        END_IF;
    2: (* Éxito *)
        (* Mantener ok activo hasta el siguiente intercambio *)
    3: (* Error *)
        (* Mantener error activo hasta el siguiente intercambio *)
END_CASE;

nIntentos := intentos;
END_FUNCTION_BLOCK