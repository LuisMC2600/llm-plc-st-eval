FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL;   (* Boton de paro normal *)
    btnEmerg : BOOL;  (* Boton de paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL;   (* Estado de activacion del motor *)
END_VAR
VAR
    flancoMarcha : R_TRIG; (* Detector de flanco para evitar rearranque accidental *)
END_VAR

(* Detecta solo el instante en que se pulsa la marcha *)
flancoMarcha(CLK := btnMarcha);

(* Logica de enclavamiento: prioridad a las senales de paro *)
IF btnParo OR btnEmerg THEN
    motorOn := FALSE;
ELSIF flancoMarcha.Q THEN
    motorOn := TRUE;
END_IF;
END_FUNCTION_BLOCK