```st
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo   : BOOL; (* Boton de paro *)
    btnEmerg  : BOOL; (* Boton de paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Salida del contactor del motor *)
END_VAR
VAR
    bloqEmerg : BOOL; (* Bloqueo activo tras paro de emergencia *)
END_VAR

(* Activar bloqueo ante paro de emergencia; se mantiene hasta que
   btnMarcha se suelte, evitando un rearranque involuntario *)
IF btnEmerg THEN
    bloqEmerg := TRUE;
END_IF;

(* Liberar bloqueo solo cuando el operador suelte el boton de marcha *)
IF bloqEmerg AND NOT btnMarcha THEN
    bloqEmerg := FALSE;
END_IF;

(* Logica de arranque/paro con autoretencion:
   - SET:   btnMarcha activo y sin bloqueo de emergencia
   - RESET: btnParo, btnEmerg o bloqueo activo *)
IF btnMarcha AND NOT bloqEmerg THEN
    motorOn := TRUE;
END_IF;

IF btnParo OR btnEmerg OR bloqEmerg THEN
    motorOn := FALSE;
END_IF;

END_FUNCTION_BLOCK
```