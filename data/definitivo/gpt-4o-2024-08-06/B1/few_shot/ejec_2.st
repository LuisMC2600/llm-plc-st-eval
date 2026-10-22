```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL;   (* Boton de paro *)
    btnEmerg : BOOL;  (* Boton de paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL;   (* Estado del motor *)
END_VAR
VAR
    motorLatch : BOOL; (* Latch para mantener el motor encendido *)
END_VAR

(* Control de arranque y paro del motor *)
IF btnEmerg THEN
    (* Si se activa el paro de emergencia, el motor se apaga y no puede rearrancar *)
    motorLatch := FALSE;
ELSIF btnParo THEN
    (* Si se pulsa el boton de paro, el motor se apaga *)
    motorLatch := FALSE;
ELSIF btnMarcha THEN
    (* Si se pulsa el boton de marcha, el motor se enciende y se mantiene encendido *)
    motorLatch := TRUE;
END_IF

(* Actualizar el estado del motor *)
motorOn := motorLatch;
END_FUNCTION_BLOCK
```