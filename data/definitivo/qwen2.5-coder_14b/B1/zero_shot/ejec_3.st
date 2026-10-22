```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL;  // Botón de marcha
    btnParo : BOOL;    // Botón de paro
    btnEmerg : BOOL;   // Botón de paro de emergencia
END_VAR

VAR_OUTPUT
    motorOn : BOOL;    // Estado del motor (encendido/apagado)
END_VAR

VAR
    emergenciaActiva : BOOL := FALSE;  // Bandera para indicar si hay una parada de emergencia
END_VAR

// Programa principal
IF btnEmerg THEN
    // Si se detecta una parada de emergencia
    emergenciaActiva := TRUE;
    motorOn := FALSE;  // Apaga el motor
ELSEIF emergenciaActiva THEN
    // Si hay una parada de emergencia activa, no se permite el arranque
    motorOn := FALSE;
ELSEIF btnParo THEN
    // Si se presiona el botón de paro
    motorOn := FALSE;  // Apaga el motor
ELSEIF btnMarcha THEN
    // Si se presiona el botón de marcha
    motorOn := TRUE;   // Enciende el motor
END_IF
```

Este código implementa un control de arranque y paro de un motor trifásico siguiendo las especificaciones proporcionadas. El motor se enciende al presionar el botón de marcha y se mantiene encendido al soltarlo, a menos que se presione el botón de paro o se active una parada de emergencia. Una vez que se activa una parada de emergencia, el motor no se puede volver a encender incluso si se presiona el botón de marcha.