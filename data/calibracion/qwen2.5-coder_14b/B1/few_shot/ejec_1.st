FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro *)
    btnEmerg : BOOL; (* Boton de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Estado del motor *)
END_VAR
VAR
    motorStart : BOOL; (* Bandera de arranque *)
    motorStop : BOOL; (* Bandera de paro *)
    emergStop : BOOL; (* Bandera de paro de emergencia *)
END_VAR

(* Control de arranque y paro del motor *)
motorStart := btnMarcha AND NOT motorStop AND NOT emergStop;
motorStop := btnParo OR emergStop;
emergStop := btnEmerg;

(* Actualizar el estado del motor *)
IF motorStart THEN
    motorOn := TRUE;
ELSIF motorStop THEN
    motorOn := FALSE;
END_IF;
END_FUNCTION_BLOCK