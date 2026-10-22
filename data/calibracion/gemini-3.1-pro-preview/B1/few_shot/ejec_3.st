FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL;   (* Boton de paro *)
    btnEmerg : BOOL;  (* Paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL;   (* Estado del motor *)
END_VAR
VAR
    flancoMarcha : R_TRIG; (* Detector de flanco para evitar rearranque *)
END_VAR

(* Detectar flanco de subida para evitar rearranque si el boton sigue pulsado *)
flancoMarcha(CLK := btnMarcha);

(* Control de arranque y paro con prioridad a la detencion *)
IF btnParo OR btnEmerg THEN
    motorOn := FALSE;
ELSIF flancoMarcha.Q THEN
    motorOn := TRUE;
END_IF;
END_FUNCTION_BLOCK