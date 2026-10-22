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
    motorLatch : BOOL;  // Latch para mantener el estado del motor
    emergStopLatch : BOOL; // Latch para el estado de paro de emergencia
END_VAR

// Implementación del control de arranque y paro del motor
IF btnEmerg THEN
    // Si se presiona el botón de emergencia, activar el latch de emergencia
    emergStopLatch := TRUE;
    motorLatch := FALSE; // Apagar el motor inmediatamente
ELSIF btnParo THEN
    // Si se presiona el botón de paro, apagar el motor
    motorLatch := FALSE;
ELSIF btnMarcha AND NOT emergStopLatch THEN
    // Si se presiona el botón de marcha y no hay paro de emergencia, encender el motor
    motorLatch := TRUE;
END_IF

// Actualizar la salida del motor
motorOn := motorLatch;
```

Este código implementa el control de arranque y paro de un motor trifásico utilizando un bloque de función en Structured Text (ST). El motor se mantiene encendido al soltar el botón de marcha y se apaga al presionar el botón de paro o el de emergencia. El paro de emergencia impide que el motor vuelva a arrancar hasta que se restablezca el sistema.