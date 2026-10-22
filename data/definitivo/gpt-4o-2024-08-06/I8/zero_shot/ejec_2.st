```pascal
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL;       // Presión de aceite correcta
    tempOk : BOOL;       // Temperatura correcta
    sinAlm : BOOL;       // Ausencia de alarmas
    btnMarcha : BOOL;    // Botón de marcha
    btnParo : BOOL;      // Botón de paro
END_VAR

VAR_OUTPUT
    comp : BOOL;         // Estado del compresor
    causaBloqueo : INT;  // Causa de bloqueo
END_VAR

VAR
    pOilOkTimer : TON;   // Temporizador para presión de aceite
    marchaPrev : BOOL;   // Estado anterior de btnMarcha
END_VAR

// Inicialización del temporizador
pOilOkTimer(IN := pOilOk, PT := T#3S);

// Lógica para determinar la causa de bloqueo
IF NOT pOilOk THEN
    causaBloqueo := 1; // Falta presión de aceite
ELSIF NOT tempOk THEN
    causaBloqueo := 2; // Falta temperatura correcta
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; // Hay alarmas activas
ELSE
    causaBloqueo := 0; // No hay bloqueos
END_IF;

// Lógica de control del compresor
IF btnParo THEN
    comp := FALSE; // Parar el compresor si se pulsa btnParo
ELSIF comp THEN
    // Mantener el compresor en marcha si está en marcha y no hay bloqueos
    IF NOT (pOilOkTimer.Q AND tempOk AND sinAlm) THEN
        comp := FALSE; // Parar si se pierde algún permisivo
    END_IF;
ELSE
    // Arrancar el compresor si se pulsa btnMarcha y se cumplen los permisivos
    IF btnMarcha AND NOT marchaPrev AND pOilOkTimer.Q AND tempOk AND sinAlm THEN
        comp := TRUE;
    END_IF;
END_IF;

// Actualizar el estado anterior de btnMarcha
marchaPrev := btnMarcha;

END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Compresor` que controla el arranque y paro de un compresor basado en varios permisivos y entradas de control. Utiliza un temporizador para verificar que la presión de aceite sea correcta durante 3 segundos continuos antes de permitir el arranque. La causa de bloqueo se actualiza según el permisivo que falta, y el compresor se detiene si se pierde cualquier permisivo o si se pulsa el botón de paro.