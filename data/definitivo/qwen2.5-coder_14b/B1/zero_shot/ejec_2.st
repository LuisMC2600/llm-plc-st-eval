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
    emergenciaActiva : BOOL := FALSE;  // Bandera para indicar si hay una emergencia activa
END_VAR

// Programa principal
IF btnEmerg THEN
    // Si se activa el botón de emergencia
    emergenciaActiva := TRUE;
    motorOn := FALSE;  // Apaga el motor
ELSEIF emergenciaActiva THEN
    // Si hay una emergencia activa, no se permite el arranque del motor
    motorOn := FALSE;
ELSEIF btnParo THEN
    // Si se presiona el botón de paro
    motorOn := FALSE;  // Apaga el motor
ELSEIF btnMarcha THEN
    // Si se presiona el botón de marcha
    motorOn := TRUE;   // Enciende el motor
END_IF;
```

Este código implementa un control de arranque y paro de un motor trifásico siguiendo las especificaciones proporcionadas. El motor se encenderá cuando se presione el botón de marcha y se mantendrá encendido incluso si se suelta el botón. El motor se apagará si se presiona el botón de paro o el botón de paro de emergencia. Una vez que se activa el paro de emergencia, el motor no podrá ser reiniciado hasta que se resuelva la emergencia.