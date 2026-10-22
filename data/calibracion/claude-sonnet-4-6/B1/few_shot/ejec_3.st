```pascal
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

(* Activar bloqueo de emergencia; solo se libera al soltar btnEmerg *)
IF btnEmerg THEN
    bloqEmerg := TRUE;
ELSIF NOT btnEmerg AND NOT motorOn THEN
    (* Se libera el bloqueo cuando la emergencia se suelta y el motor esta parado *)
    bloqEmerg := FALSE;
END_IF;

(* Logica de arranque y paro con autoretencion *)
IF btnParo OR btnEmerg OR bloqEmerg THEN
    (* Paro normal, emergencia o bloqueo activo: apagar motor *)
    motorOn := FALSE;
ELSIF btnMarcha AND NOT bloqEmerg THEN
    (* Arranque solo si no hay bloqueo de emergencia *)
    motorOn := TRUE;
END_IF;

END_FUNCTION_BLOCK
```