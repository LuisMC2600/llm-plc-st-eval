```pascal
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
    bloqEmerg : BOOL; (* Bloqueo por emergencia: impide rearranque *)
END_VAR

(* --- Gestion del bloqueo de emergencia --- *)
(* Se activa con btnEmerg y solo se libera cuando btnEmerg vuelve a FALSE *)
(* y el operador no mantiene pulsado btnMarcha (condicion de reset seguro) *)
IF btnEmerg THEN
    bloqEmerg := TRUE;  (* Latch de emergencia *)
ELSIF NOT btnEmerg AND NOT btnMarcha THEN
    bloqEmerg := FALSE; (* Reset del bloqueo solo cuando ambas condiciones son seguras *)
END_IF;

(* --- Logica de arranque / paro con autoretencion --- *)
(* Paro de emergencia o paro normal apagan el motor                        *)
(* El bloqueo impide rearranque tras emergencia aunque btnMarcha este activo *)
IF btnEmerg OR btnParo THEN
    motorOn := FALSE;           (* Paro inmediato por emergencia o paro normal *)
ELSIF btnMarcha AND NOT bloqEmerg THEN
    motorOn := TRUE;            (* Arranque: solo si no hay bloqueo activo *)
END_IF;
(* La autoretencion queda implicita: motorOn mantiene su valor al soltar btnMarcha *)

END_FUNCTION_BLOCK
```