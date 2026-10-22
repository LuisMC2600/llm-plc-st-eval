```iecst
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // TRUE al pulsar (Contacto NA)
    btnParo   : BOOL; // TRUE al pulsar (Asumiendo lógica positiva para el ejemplo)
    btnEmerg  : BOOL; // TRUE al pulsar (Asumiendo lógica positiva para el ejemplo)
END_VAR

VAR_OUTPUT
    motorOn   : BOOL; // TRUE = Motor encendido, FALSE = Motor detenido
END_VAR

VAR
    rtMarcha  : R_TRIG; // Detector de flanco ascendente para el botón de marcha
END_VAR

// 1. Detectar el flanco ascendente (transición de FALSE a TRUE) del botón de marcha.
// Esto evita el rearranque automático si el botón se mantiene pulsado tras una emergencia.
rtMarcha(CLK := btnMarcha);

// 2. Lógica de control del motor (Enclavamiento con prioridad al paro).
// El motor se enciende con el flanco de marcha o se mantiene encendido (motorOn),
// siempre y cuando no se pulse el paro normal ni el paro de emergencia.
motorOn := (motorOn OR rtMarcha.Q) AND NOT btnParo AND NOT btnEmerg;

END_FUNCTION_BLOCK
```