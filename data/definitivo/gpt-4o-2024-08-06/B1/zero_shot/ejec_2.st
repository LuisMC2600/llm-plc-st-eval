```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL;   // Botón de paro
    btnEmerg : BOOL;  // Botón de paro de emergencia
END_VAR

VAR_OUTPUT
    motorOn : BOOL;   // Estado del motor: encendido o apagado
END_VAR

VAR
    estadoMotor : BOOL := FALSE; // Estado interno del motor
    emergenciaActiva : BOOL := FALSE; // Estado de emergencia
END_VAR

// Lógica de control del motor
IF btnEmerg THEN
    // Si el botón de emergencia está presionado, activar estado de emergencia
    emergenciaActiva := TRUE;
    estadoMotor := FALSE;
ELSIF btnParo THEN
    // Si el botón de paro está presionado, apagar el motor
    estadoMotor := FALSE;
ELSIF btnMarcha AND NOT emergenciaActiva THEN
    // Si el botón de marcha está presionado y no hay emergencia, encender el motor
    estadoMotor := TRUE;
END_IF

// Actualizar la salida del motor
motorOn := estadoMotor;
END_FUNCTION_BLOCK
```

Este código implementa el control de arranque y paro de un motor trifásico utilizando un bloque de función en Structured Text (ST) conforme al estándar IEC 61131-3. El motor se mantiene encendido después de soltar el botón de marcha y se apaga al presionar el botón de paro o el de emergencia. Una vez activada la emergencia, el motor no puede rearrancar hasta que se restablezca el estado de emergencia.