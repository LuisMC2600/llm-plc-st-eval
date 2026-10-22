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
    flancoMarcha : R_TRIG; (* Detector de flanco para evitar rearranque *)
END_VAR

(* Detecta solo el instante en que se presiona el boton de marcha *)
flancoMarcha(CLK := btnMarcha);

(* Logica de enclavamiento con prioridad a las señales de paro *)
motorOn := (motorOn OR flancoMarcha.Q) AND NOT (btnParo OR btnEmerg);
END_FUNCTION_BLOCK