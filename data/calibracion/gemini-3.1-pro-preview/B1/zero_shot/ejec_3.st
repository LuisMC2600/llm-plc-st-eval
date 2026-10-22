```iecst
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha (arranque)
    btnParo   : BOOL; // Botón de paro normal (TRUE = pulsado para detener)
    btnEmerg  : BOOL; // Botón de paro de emergencia (TRUE = pulsado para detener)
END_VAR

VAR_OUTPUT
    motorOn   : BOOL; // Señal de activación del motor
END_VAR

VAR
    flancoMarcha : R_TRIG; // Detector de flanco ascendente estándar IEC 61131-3
END_VAR

// Detectar el flanco positivo (pulsación) del botón de marcha.
// Esto evita el rearranque automático si el botón se mantiene pulsado tras una emergencia.
flancoMarcha(CLK := btnMarcha);

// Lógica de control del motor (Enclavamiento)
// Prioridad a las señales de paro (NOT btnParo AND NOT btnEmerg)
motorOn := (flancoMarcha.Q OR motorOn) AND NOT btnParo AND NOT btnEmerg;

END_FUNCTION_BLOCK
```