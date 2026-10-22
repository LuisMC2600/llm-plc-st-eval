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
    trigMarcha : R_TRIG; (* Detector de flanco para evitar rearranque *)
END_VAR

(* Detecta el flanco de subida de la marcha para que no rearranque si se mantiene pulsado *)
trigMarcha(CLK := btnMarcha);

(* Enclavamiento del motor con prioridad a las señales de paro *)
motorOn := (motorOn OR trigMarcha.Q) AND NOT btnParo AND NOT btnEmerg;
END_FUNCTION_BLOCK