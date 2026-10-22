```pascal
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
    emergStop : BOOL;   // Estado de paro de emergencia
END_VAR

// Lógica de control del motor
IF btnEmerg THEN
    // Si el botón de emergencia está presionado, detener el motor
    motorOn := FALSE;
    emergStop := TRUE;
ELSIF btnParo THEN
    // Si el botón de paro está presionado, detener el motor
    motorOn := FALSE;
ELSIF btnMarcha AND NOT emergStop THEN
    // Si el botón de marcha está presionado y no hay paro de emergencia, arrancar el motor
    motorOn := TRUE;
END_IF

// Actualizar el estado del latch del motor
motorLatch := motorOn;

// Si el motor está encendido, mantenerlo encendido
IF motorLatch THEN
    motorOn := TRUE;
END_IF

// Resetear el estado de paro de emergencia si el motor está apagado
IF NOT motorOn THEN
    emergStop := FALSE;
END_IF

END_FUNCTION_BLOCK
```

Este código implementa la lógica de control de arranque y paro de un motor trifásico conforme a los requisitos especificados. El motor se mantiene encendido al soltar el botón de marcha y se detiene al presionar el botón de paro o el paro de emergencia. Después de un paro de emergencia, el motor no rearranca automáticamente.