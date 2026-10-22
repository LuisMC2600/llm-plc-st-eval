```pascal
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
    motorLatch : BOOL; (* Latch para mantener el motor encendido *)
END_VAR

(* Control de arranque y paro del motor *)
IF btnEmerg THEN
    motorLatch := FALSE; (* Paro de emergencia, el motor no puede rearrancar *)
ELSIF btnParo THEN
    motorLatch := FALSE; (* Paro normal, apaga el motor *)
ELSIF btnMarcha THEN
    motorLatch := TRUE;  (* Arranca el motor y lo mantiene encendido *)
END_IF

motorOn := motorLatch; (* Actualiza el estado del motor *)
END_FUNCTION_BLOCK
```