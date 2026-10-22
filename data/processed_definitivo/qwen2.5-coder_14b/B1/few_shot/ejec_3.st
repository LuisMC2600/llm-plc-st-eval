FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro *)
    btnEmerg : BOOL; (* Boton de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Motor encendido *)
END_VAR
VAR
    estadoEmergencia : BOOL := FALSE; (* Estado de emergencia *)
END_VAR

(* Control de arranque y paro del motor *)
IF btnEmerg THEN
    estadoEmergencia := TRUE;
    motorOn := FALSE;
ELSIF estadoEmergencia THEN
    motorOn := FALSE;
ELSIF btnParo THEN
    motorOn := FALSE;
ELSIF btnMarcha THEN
    motorOn := TRUE;
END_IF;
END_FUNCTION_BLOCK