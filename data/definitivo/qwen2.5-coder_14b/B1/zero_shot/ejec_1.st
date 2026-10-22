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
    // Si se activa el botón de emergencia, detener el motor y activar la bandera de emergencia
    motorOn := FALSE;
    emergenciaActiva := TRUE;
ELSIF emergenciaActiva THEN
    // Si hay una parada de emergencia activa, mantener el motor apagado
    motorOn := FALSE;
ELSIF btnParo THEN
    // Si se presiona el botón de paro, detener el motor
    motorOn := FALSE;
ELSIF btnMarcha THEN
    // Si se presiona el botón de marcha, encender el motor
    motorOn := TRUE;
END_IF;
```

Este código implementa un control de arranque y paro de un motor trifásico siguiendo las especificaciones proporcionadas. El motor se enciende al presionar el botón de marcha y se mantiene encendido al soltarlo. El motor se detiene al presionar el botón de paro o el botón de paro de emergencia. Una vez que se activa el botón de paro de emergencia, el motor no se puede volver a encender aunque el botón de marcha siga pulsado.