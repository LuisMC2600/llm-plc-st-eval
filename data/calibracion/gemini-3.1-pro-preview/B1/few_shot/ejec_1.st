FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro normal *)
    btnEmerg : BOOL; (* Boton de paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Activacion del motor *)
END_VAR
VAR
    trigMarcha : R_TRIG; (* Detector de flanco para evitar rearranque *)
END_VAR

(* Detecta nueva pulsacion de marcha para evitar rearranque si el boton sigue presionado *)
trigMarcha(CLK := btnMarcha);

(* Enclavamiento del motor con prioridad a las senales de paro *)
motorOn := (trigMarcha.Q OR motorOn) AND NOT btnParo AND NOT btnEmerg;
END_FUNCTION_BLOCK