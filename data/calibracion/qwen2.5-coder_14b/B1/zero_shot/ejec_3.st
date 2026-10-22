```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL; // Botón de paro
    btnEmerg : BOOL; // Botón de emergencia
END_VAR

VAR_OUTPUT
    motorOn : BOOL; // Estado del motor (encendido/apagado)
END_VAR

VAR
    emergenciaActiva : BOOL := FALSE; // Estado de emergencia activa
END_VAR

// Programa principal
IF btnEmerg THEN
    emergenciaActiva := TRUE; // Activar estado de emergencia
    motorOn := FALSE; // Apagar motor en caso de emergencia
ELSIF emergenciaActiva THEN
    motorOn := FALSE; // Mantener motor apagado si hay emergencia activa
ELSE
    IF btnParo THEN
        motorOn := FALSE; // Apagar motor si se presiona el botón de paro
    ELSE
        motorOn := btnMarcha; // Mantener motor encendido si se mantiene presionado el botón de marcha
    END_IF
END_IF;
```

Este código implementa un control de arranque y paro de un motor trifásico siguiendo las especificaciones proporcionadas. El motor se encenderá cuando se presione el botón de marcha y se mantendrá encendido mientras se mantenga presionado. El motor se apagará cuando se presione el botón de paro o el botón de emergencia. Después de un paro de emergencia, el motor no se podrá volver a encender aunque se mantenga presionado el botón de marcha.