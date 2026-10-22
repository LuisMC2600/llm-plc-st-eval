```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL; // Botón de paro
    btnEmerg : BOOL; // Botón de emergencia
END_VAR

VAR_OUTPUT
    motorOn : BOOL; // Estado del motor
END_VAR

VAR
    estadoEmergencia : BOOL := FALSE; // Bandera de emergencia
END_VAR

// Programa principal
IF btnEmerg THEN
    // Si se presiona el botón de emergencia
    estadoEmergencia := TRUE;
    motorOn := FALSE; // Apaga el motor
ELSIF estadoEmergencia THEN
    // Si hay una emergencia activa, no se permite el arranque
    motorOn := FALSE;
ELSIF btnParo THEN
    // Si se presiona el botón de paro
    motorOn := FALSE; // Apaga el motor
ELSIF btnMarcha THEN
    // Si se presiona el botón de marcha
    motorOn := TRUE; // Enciende el motor
END_IF;
```

Este código implementa un control de arranque y paro de un motor trifásico siguiendo las especificaciones proporcionadas. El motor se encenderá cuando se presione el botón de marcha y permanecerá encendido incluso al soltar el botón. El motor se apagará cuando se presione el botón de paro o el botón de emergencia. Después de un paro de emergencia, el motor no se podrá arrancar aunque el botón de marcha esté pulsado.