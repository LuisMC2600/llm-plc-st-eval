FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL;   // Botón de marcha
    btnParo   : BOOL;   // Botón de paro
    btnEmerg  : BOOL;   // Botón de paro de emergencia
END_VAR

VAR_OUTPUT
    motorOn   : BOOL;   // Estado del motor (encendido/apagado)
END_VAR

VAR
    motorLatch : BOOL;  // Latch interno para mantener el estado del motor
    emergStopLatch : BOOL; // Latch para el estado de paro de emergencia
END_VAR

// Lógica de control del motor
IF btnEmerg THEN
    // Si se presiona el botón de emergencia, activar el latch de emergencia y apagar el motor
    emergStopLatch := TRUE;
    motorLatch := FALSE;
ELSIF btnParo THEN
    // Si se presiona el botón de paro, apagar el motor
    motorLatch := FALSE;
ELSIF btnMarcha AND NOT emergStopLatch THEN
    // Si se presiona el botón de marcha y no hay paro de emergencia, encender el motor
    motorLatch := TRUE;
END_IF

// El motor está encendido si el latch del motor está activo
motorOn := motorLatch;

// Reset del latch de emergencia si el motor está apagado
IF NOT motorLatch THEN
    emergStopLatch := FALSE;
END_IF

END_FUNCTION_BLOCK