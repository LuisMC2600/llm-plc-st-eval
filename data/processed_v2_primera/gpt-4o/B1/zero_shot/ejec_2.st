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
    emergStopLatch : BOOL; // Latch para mantener el estado de paro de emergencia
END_VAR

// Comportamiento del bloque de función
IF btnEmerg THEN
    // Si el botón de emergencia está presionado, activar el latch de emergencia
    emergStopLatch := TRUE;
    motorLatch := FALSE; // Asegurar que el motor se apague
ELSIF btnParo THEN
    // Si el botón de paro está presionado, apagar el motor
    motorLatch := FALSE;
ELSIF btnMarcha AND NOT emergStopLatch THEN
    // Si el botón de marcha está presionado y no hay paro de emergencia, encender el motor
    motorLatch := TRUE;
END_IF

// Si el paro de emergencia se desactiva, resetear el latch de emergencia
IF NOT btnEmerg THEN
    emergStopLatch := FALSE;
END_IF

// Actualizar la salida del motor
motorOn := motorLatch;

END_FUNCTION_BLOCK