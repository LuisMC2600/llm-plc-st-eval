FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo   : BOOL; (* Boton de paro *)
    btnEmerg  : BOOL; (* Boton de paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Salida del motor *)
END_VAR
VAR
    bloqEmerg : BOOL; (* Bloqueo activo tras emergencia *)
END_VAR

(* Activar bloqueo de emergencia; solo se libera al ciclo siguiente sin emergencia *)
IF btnEmerg THEN
    bloqEmerg := TRUE;
END_IF;

(* Logica de arranque/paro con autoretencion *)
(* Paro normal o emergencia detienen el motor                *)
(* El bloqueo impide rearranque hasta que se libere          *)
IF btnParo OR btnEmerg THEN
    motorOn := FALSE;
ELSIF btnMarcha AND NOT bloqEmerg THEN
    motorOn := TRUE;
END_IF;

(* Liberar bloqueo de emergencia solo cuando no hay emergencia ni motor en marcha *)
IF NOT btnEmerg AND NOT motorOn THEN
    bloqEmerg := FALSE;
END_IF;

END_FUNCTION_BLOCK