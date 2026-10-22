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
    emergStop : BOOL;   // Estado del paro de emergencia
END_VAR

// Lógica de control del motor
IF btnEmerg THEN
    // Si el botón de emergencia está presionado, apaga el motor y activa el estado de emergencia
    motorOn := FALSE;
    emergStop := TRUE;
ELSIF btnParo THEN
    // Si el botón de paro está presionado, apaga el motor
    motorOn := FALSE;
ELSE
    // Si no hay emergencia y el botón de marcha está presionado, y no hay estado de emergencia
    IF btnMarcha AND NOT emergStop THEN
        motorLatch := TRUE;  // Activa el latch del motor
    END_IF;
    
    // Mantiene el motor encendido si el latch está activo
    motorOn := motorLatch;
END_IF;

// Resetea el latch del motor si el motor está apagado
IF NOT motorOn THEN
    motorLatch := FALSE;
END_IF;
```

Este código implementa la lógica de control para el arranque y paro de un motor trifásico utilizando un bloque de función en Structured Text (ST). El motor se mantiene encendido mediante un latch (`motorLatch`) y se apaga al presionar el botón de paro o el de emergencia. El estado de emergencia impide el rearranque del motor hasta que se resetea.