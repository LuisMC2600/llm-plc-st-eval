FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // Botón de arranque (TRUE = arrancar)
    btnParo   : BOOL; // Botón de paro normal (TRUE = detener)
    btnEmerg  : BOOL; // Botón de paro de emergencia (TRUE = detener)
END_VAR

VAR_OUTPUT
    motorOn   : BOOL; // Señal de control hacia el contactor del motor
END_VAR

VAR
    flancoMarcha : R_TRIG; // Detector de flanco para el botón de marcha
END_VAR

// Detectar el flanco de subida de la señal de marcha.
// Esto garantiza que el motor no rearranque automáticamente si el 
// botón de marcha se mantiene presionado tras un paro de emergencia.
flancoMarcha(CLK := btnMarcha);

// Lógica de control: 
// Enclavamiento del motor (flancoMarcha.Q OR motorOn) 
// condicionado a que no haya ninguna señal de paro activa.
// El paro y la emergencia tienen prioridad sobre el arranque.
motorOn := (flancoMarcha.Q OR motorOn) AND NOT btnParo AND NOT btnEmerg;

END_FUNCTION_BLOCK