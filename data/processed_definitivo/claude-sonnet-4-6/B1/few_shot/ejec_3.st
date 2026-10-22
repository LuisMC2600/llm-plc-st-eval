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

(* Activar bloqueo ante paro de emergencia; se mantiene hasta nuevo ciclo de paro normal *)
IF btnEmerg THEN
    bloqEmerg := TRUE;
END_IF;

(* Desbloquear solo cuando se pulsa paro sin emergencia activa *)
IF btnParo AND NOT btnEmerg THEN
    bloqEmerg := FALSE;
END_IF;

(* Logica de arranque con autoretencion:
   - Arranca si btnMarcha y no hay bloqueo de emergencia
   - Para si btnParo o btnEmerg                          *)
IF (btnParo OR btnEmerg) THEN
    motorOn := FALSE;
ELSIF btnMarcha AND NOT bloqEmerg THEN
    motorOn := TRUE;
END_IF;
(* Si ninguna condicion se cumple, motorOn conserva su estado anterior (autoretencion) *)

END_FUNCTION_BLOCK