```pascal
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
    bloqEmerg : BOOL; (* Bloqueo activo tras paro de emergencia *)
END_VAR

(* Activar bloqueo de emergencia; solo se libera al soltar btnEmerg *)
IF btnEmerg THEN
    bloqEmerg := TRUE;
ELSIF NOT btnEmerg AND NOT btnMarcha THEN
    (* El bloqueo se libera cuando se sueltan emergencia y marcha *)
    bloqEmerg := FALSE;
END_IF;

(* Logica de arranque/paro con autoretencion *)
IF btnParo OR btnEmerg OR bloqEmerg THEN
    (* Paro normal, emergencia o bloqueo activo: apagar motor *)
    motorOn := FALSE;
ELSIF btnMarcha AND NOT bloqEmerg THEN
    (* Arranque: activar motor *)
    motorOn := TRUE;
END_IF;
(* Si ninguna condicion aplica, motorOn conserva su estado (autoretencion) *)

END_FUNCTION_BLOCK
```