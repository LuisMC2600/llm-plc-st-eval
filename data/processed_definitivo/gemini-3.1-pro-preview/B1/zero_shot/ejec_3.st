FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // TRUE al pulsar para arrancar
    btnParo   : BOOL; // TRUE al pulsar para detener
    btnEmerg  : BOOL; // TRUE al activar el paro de emergencia
END_VAR

VAR_OUTPUT
    motorOn   : BOOL; // Estado del motor (TRUE = Encendido)
END_VAR

VAR
    rtMarcha  : R_TRIG; // Detector de flanco de subida para el botón de marcha
END_VAR

// Detección de flanco ascendente para evitar el rearranque automático 
// si el botón de marcha se mantiene pulsado tras una emergencia.
rtMarcha(CLK := btnMarcha);

// Lógica de control: Enclavamiento con paro dominante.
// El motor se enciende con el flanco de marcha y se mantiene (motorOn).
// Se detiene inmediatamente si btnParo o btnEmerg son TRUE.
motorOn := (motorOn OR rtMarcha.Q) AND NOT btnParo AND NOT btnEmerg;

END_FUNCTION_BLOCK