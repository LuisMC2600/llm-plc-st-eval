FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL;   // Botón de marcha
    btnParo : BOOL;     // Botón de paro
    btnEmerg : BOOL;    // Botón de paro de emergencia
END_VAR

VAR_OUTPUT
    motorOn : BOOL;     // Estado del motor
END_VAR

VAR
    motorLatch : BOOL;  // Latch para mantener el estado del motor
    emergStop : BOOL;   // Estado del paro de emergencia
END_VAR

// Inicio del cuerpo del FUNCTION_BLOCK
IF btnEmerg THEN
    // Si el botón de emergencia está presionado, activar el paro de emergencia
    emergStop := TRUE;
    motorLatch := FALSE; // Asegurar que el motor se apague
ELSIF btnParo THEN
    // Si el botón de paro está presionado, apagar el motor
    motorLatch := FALSE;
ELSIF btnMarcha AND NOT emergStop THEN
    // Si el botón de marcha está presionado y no hay paro de emergencia, encender el motor
    motorLatch := TRUE;
END_IF

// Actualizar la salida del motor
motorOn := motorLatch;

// Reiniciar el estado de paro de emergencia si el motor está apagado
IF NOT motorOn THEN
    emergStop := FALSE;
END_IF

END_FUNCTION_BLOCK