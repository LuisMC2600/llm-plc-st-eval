```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; // Sensor que detecta la presencia de una pieza
    sensorAltura : BOOL;    // Sensor que detecta si la pieza es alta
END_VAR

VAR_OUTPUT
    banda : BOOL;   // Salida para activar la banda transportadora
    piston : BOOL;  // Salida para activar el pistón desviador
    nAltas : INT;   // Contador de piezas altas
    nBajas : INT;   // Contador de piezas bajas
END_VAR

VAR
    timerRetraso : TON; // Temporizador para el retraso de 2 segundos
    timerPiston : TON;  // Temporizador para la activación del pistón durante 1 segundo
    piezaDetectada : BOOL; // Indica si una pieza ha sido detectada
    piezaAlta : BOOL; // Indica si la pieza detectada es alta
END_VAR

// Inicialización de la banda transportadora
banda := TRUE;

// Detección de una pieza
IF sensorPresencia AND NOT piezaDetectada THEN
    piezaDetectada := TRUE;
    piezaAlta := sensorAltura;
    timerRetraso(IN := TRUE, PT := T#2S); // Inicia el temporizador de retraso
END_IF

// Manejo del temporizador de retraso
IF timerRetraso.Q THEN
    timerRetraso(IN := FALSE); // Detiene el temporizador de retraso

    IF piezaAlta THEN
        timerPiston(IN := TRUE, PT := T#1S); // Inicia el temporizador del pistón
        nAltas := nAltas + 1; // Incrementa el contador de piezas altas
    ELSE
        nBajas := nBajas + 1; // Incrementa el contador de piezas bajas
    END_IF

    piezaDetectada := FALSE; // Reinicia la detección de pieza
END_IF

// Manejo del temporizador del pistón
IF timerPiston.Q THEN
    piston := FALSE; // Desactiva el pistón
    timerPiston(IN := FALSE); // Detiene el temporizador del pistón
ELSE
    piston := timerPiston.Q; // Activa el pistón mientras el temporizador está activo
END_IF

END_FUNCTION_BLOCK
```

Este código implementa un bloque de función `FB_Clasificadora` que controla una banda transportadora clasificadora. La banda funciona continuamente, y las piezas se clasifican en altas y bajas según la entrada de los sensores. El pistón se activa para desviar las piezas altas después de un retraso de 2 segundos y se mantiene activo durante 1 segundo. Los contadores `nAltas` y `nBajas` llevan un registro del número de piezas altas y bajas, respectivamente.