FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha *)
    btnParo : BOOL;   (* Botón de paro *)
    btnEmerg : BOOL;  (* Botón de paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL;   (* Estado del motor *)
END_VAR
VAR
    motorLatch : BOOL; (* Latch para mantener el estado del motor *)
END_VAR

(* Control de arranque y paro del motor *)
IF btnEmerg THEN
    motorLatch := FALSE; (* Paro de emergencia, motor no rearranca *)
ELSIF btnParo THEN
    motorLatch := FALSE; (* Paro normal, motor se apaga *)
ELSIF btnMarcha THEN
    motorLatch := TRUE;  (* Arranque del motor, se mantiene encendido *)
END_IF

motorOn := motorLatch; (* Salida del estado del motor *)
END_FUNCTION_BLOCK