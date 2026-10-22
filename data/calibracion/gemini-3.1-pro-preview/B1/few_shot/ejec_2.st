FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro *)
    btnEmerg : BOOL; (* Paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Estado del motor *)
END_VAR
VAR
    trigMarcha : R_TRIG; (* Detector de flanco de subida *)
END_VAR

(* Deteccion del flanco de subida para evitar rearranque si el boton sigue pulsado *)
trigMarcha(CLK := btnMarcha);

(* Control de arranque y paro con prioridad a las senales de detencion *)
motorOn := (trigMarcha.Q OR motorOn) AND NOT btnParo AND NOT btnEmerg;
END_FUNCTION_BLOCK