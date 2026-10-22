```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL;  // Sensor que detecta la presencia de una pieza
    sensorAltura : BOOL;     // Sensor que detecta si la pieza es alta
END_VAR

VAR_OUTPUT
    banda : BOOL;            // Salida para activar la banda transportadora
    piston : BOOL;           // Salida para activar el pistón desviador
    nAltas : INT;            // Contador de piezas altas
    nBajas : INT;            // Contador de piezas bajas
END_VAR

VAR
    timerRetraso : TON;      // Temporizador para retrasar la activación del pistón
    timerDuracion : TON;     // Temporizador para la duración del pistón activado
    presenciaDetectada : BOOL; // Indica si se ha detectado una pieza
    piezaAlta : BOOL;        // Indica si la pieza detectada es alta
END_VAR

// Inicialización de la banda transportadora
banda := TRUE;

// Detección de una pieza
IF sensorPresencia AND NOT presenciaDetectada THEN
    presenciaDetectada := TRUE;
    piezaAlta := sensorAltura;
    
    // Iniciar temporizador de retraso si la pieza es alta
    IF piezaAlta THEN
        timerRetraso(IN := TRUE, PT := T#2S);
    ELSE
        nBajas := nBajas + 1; // Incrementar contador de piezas bajas
    END_IF
END_IF

// Manejo del temporizador de retraso
IF timerRetraso.Q THEN
    timerRetraso(IN := FALSE);
    timerDuracion(IN := TRUE, PT := T#1S);
    piston := TRUE;
END_IF

// Manejo del temporizador de duración del pistón
IF timerDuracion.Q THEN
    timerDuracion(IN := FALSE);
    piston := FALSE;
    nAltas := nAltas + 1; // Incrementar contador de piezas altas
END_IF

// Reiniciar detección de presencia
IF NOT sensorPresencia THEN
    presenciaDetectada := FALSE;
END_IF

END_FUNCTION_BLOCK
```

Este código implementa un bloque de función para controlar una banda transportadora clasificadora. La banda está siempre activa, y el pistón se activa para desviar piezas altas después de un retraso de 2 segundos, permaneciendo activo durante 1 segundo. Las piezas altas y bajas se cuentan en `nAltas` y `nBajas`, respectivamente.