FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha (TRUE = pulsado)
    btnParo   : BOOL; // Botón de paro (TRUE = pulsado)
    btnEmerg  : BOOL; // Paro de emergencia (TRUE = pulsado)
END_VAR

VAR_OUTPUT
    motorOn   : BOOL; // Estado del motor (TRUE = encendido)
END_VAR

VAR
    rtMarcha  : R_TRIG; // Detector de flanco ascendente
END_VAR

// Detectar flanco ascendente de la marcha para evitar rearranque automático
// si el botón se mantiene pulsado tras un paro de emergencia.
rtMarcha(CLK := btnMarcha);

// Lógica de control (Enclavamiento)
// Prioridad a las señales de paro (btnParo y btnEmerg)
motorOn := (rtMarcha.Q OR motorOn) AND NOT btnParo AND NOT btnEmerg;

END_FUNCTION_BLOCK