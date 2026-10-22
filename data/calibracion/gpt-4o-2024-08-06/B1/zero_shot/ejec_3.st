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

// Lógica de control del motor
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

// Actualizar el estado de salida del motor
motorOn := motorLatch;

// Resetear el latch de emergencia si el motor está apagado
IF NOT motorLatch THEN
    emergStopLatch := FALSE;
END_IF

END_FUNCTION_BLOCK
```

Este código implementa un control básico de arranque y paro de un motor trifásico utilizando un bloque de función en Structured Text (ST) conforme al estándar IEC 61131-3. El motor se mantiene encendido después de soltar el botón de marcha y se apaga al presionar el botón de paro o el de emergencia. Además, el motor no se rearranca automáticamente después de un paro de emergencia hasta que se libere y vuelva a presionar el botón de marcha.