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

(* Reset del bloqueo: solo cuando la emergencia este liberada Y el motor este parado *)
IF NOT btnEmerg AND NOT motorOn THEN
    bloqEmerg := FALSE;
END_IF;

(* Logica de arranque/paro con autoretencion *)
(* Paro tiene prioridad sobre marcha; bloqueo impide rearranque tras emergencia *)
IF btnParo OR btnEmerg THEN
    motorOn := FALSE;                              (* Paro normal o emergencia *)
ELSIF btnMarcha AND NOT bloqEmerg THEN
    motorOn := TRUE;                               (* Arranque solo si no hay bloqueo *)
END_IF;

END_FUNCTION_BLOCK