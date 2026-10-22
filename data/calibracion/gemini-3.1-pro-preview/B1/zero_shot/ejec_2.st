```iecst
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // TRUE al pulsar (arranque)
    btnParo   : BOOL; // TRUE al pulsar (parada normal)
    btnEmerg  : BOOL; // TRUE al pulsar (parada de emergencia)
END_VAR

VAR_OUTPUT
    motorOn   : BOOL; // TRUE = Motor en marcha, FALSE = Motor detenido
END_VAR

VAR
    trigMarcha : R_TRIG; // Detección de flanco para evitar rearranque automático
END_VAR

// Detectar flanco ascendente del botón de marcha
trigMarcha(CLK := btnMarcha);

// Lógica de control: Prioridad a la parada
IF btnEmerg OR btnParo THEN
    motorOn := FALSE;
// Arranque por flanco para exigir soltar y volver a pulsar tras una emergencia
ELSIF trigMarcha.Q THEN
    motorOn := TRUE;
END_IF;

END_FUNCTION_BLOCK
```