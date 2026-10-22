FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha (NA) *)
    btnParo   : BOOL; (* Boton de paro (NC, activo = paro) *)
    btnEmerg  : BOOL; (* Paro de emergencia (NC, activo = emergencia) *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Contactor / salida del motor *)
END_VAR
VAR
    bloqEmerg : BOOL; (* Bloqueo activo tras paro de emergencia *)
END_VAR

(* Activar bloqueo de emergencia con flanco o nivel de btnEmerg *)
IF btnEmerg THEN
    bloqEmerg := TRUE;
END_IF;

(* Resetear bloqueo solo cuando la emergencia este liberada y el motor este parado *)
IF NOT btnEmerg AND NOT motorOn THEN
    bloqEmerg := FALSE;
END_IF;

(* Logica de arranque/paro con autoretencion:
   - Arranca : btnMarcha activo, sin paro, sin emergencia y sin bloqueo
   - Para    : btnParo o btnEmerg activos                               *)
IF (btnParo OR btnEmerg) THEN
    motorOn := FALSE;
ELSIF (btnMarcha AND NOT bloqEmerg) THEN
    motorOn := TRUE;
END_IF;

END_FUNCTION_BLOCK