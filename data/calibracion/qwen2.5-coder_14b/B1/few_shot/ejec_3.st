FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro *)
    btnEmerg : BOOL; (* Boton de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Motor encendido *)
END_VAR
VAR
    motorStarted : BOOL; (* Bandera para indicar si el motor ha sido arrancado *)
END_VAR

(* Arranque del motor *)
IF btnMarcha AND NOT motorStarted THEN
    motorStarted := TRUE;
    motorOn := TRUE;
END_IF;

(* Paro del motor *)
IF btnParo OR btnEmerg THEN
    motorStarted := FALSE;
    motorOn := FALSE;
END_IF;

(* Mantener el motor encendido después de arrancarlo *)
IF motorStarted THEN
    motorOn := TRUE;
END_IF;

END_FUNCTION_BLOCK