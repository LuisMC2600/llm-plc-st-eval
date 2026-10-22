```st
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

(* Si se activa emergencia: apagar motor y activar bloqueo *)
IF btnEmerg THEN
    bloqEmerg := TRUE;
    motorOn   := FALSE;

(* Si se pulsa paro: apagar motor (sin bloqueo) *)
ELSIF btnParo THEN
    motorOn := FALSE;

(* Arranque solo si no hay bloqueo de emergencia *)
ELSIF btnMarcha AND NOT bloqEmerg THEN
    motorOn := TRUE;
END_IF;

(* El bloqueo de emergencia se libera unicamente cuando
   btnEmerg ya no esta activo Y btnMarcha no esta pulsado,
   evitando rearranque involuntario al liberar el bloqueo *)
IF bloqEmerg AND NOT btnEmerg AND NOT btnMarcha THEN
    bloqEmerg := FALSE;
END_IF;

END_FUNCTION_BLOCK
```