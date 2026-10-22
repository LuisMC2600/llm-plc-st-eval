FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL;   // Botón de marcha
    btnParo : BOOL;     // Botón de paro
    btnEmerg : BOOL;    // Botón de paro de emergencia
END_VAR

VAR_OUTPUT
    motorOn : BOOL;     // Estado del motor (encendido/apagado)
END_VAR

VAR
    motorLatch : BOOL;  // Latch para mantener el motor encendido
    emergStopLatch : BOOL; // Latch para el estado de paro de emergencia
END_VAR

// Lógica de control del motor
IF btnEmerg THEN
    // Si el botón de emergencia está presionado, activar el latch de emergencia
    emergStopLatch := TRUE;
    motorOn := FALSE; // Apagar el motor inmediatamente
ELSIF btnParo THEN
    // Si el botón de paro está presionado, apagar el motor
    motorOn := FALSE;
ELSIF btnMarcha AND NOT emergStopLatch THEN
    // Si el botón de marcha está presionado y no hay paro de emergencia, encender el motor
    motorLatch := TRUE;
END_IF

// Mantener el motor encendido si el latch está activo
IF motorLatch AND NOT btnParo AND NOT btnEmerg THEN
    motorOn := TRUE;
ELSE
    motorOn := FALSE;
    motorLatch := FALSE; // Resetear el latch si el motor se apaga
END_IF

// Resetear el latch de emergencia si el motor está apagado y no hay emergencia
IF NOT btnEmerg THEN
    emergStopLatch := FALSE;
END_IF

END_FUNCTION_BLOCK