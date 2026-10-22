```pascal
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL;        // Presión de aceite correcta
    tempOk : BOOL;        // Temperatura correcta
    sinAlm : BOOL;        // Sin alarmas
    btnMarcha : BOOL;     // Botón de marcha
    btnParo : BOOL;       // Botón de paro
END_VAR

VAR_OUTPUT
    comp : BOOL;          // Salida del compresor
    causaBloqueo : INT;   // Causa del bloqueo
END_VAR

VAR
    pOilOkTimer : TON;    // Temporizador para presión de aceite
    btnMarchaPrev : BOOL; // Estado previo del botón de marcha
END_VAR

// Inicialización del temporizador
pOilOkTimer(IN := pOilOk, PT := T#3S);

// Evaluación de los permisivos
IF NOT pOilOkTimer.Q THEN
    causaBloqueo := 1; // Falta presión de aceite
ELSIF NOT tempOk THEN
    causaBloqueo := 2; // Falta temperatura correcta
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; // Alarma activa
ELSE
    causaBloqueo := 0; // Todos los permisivos están bien
END_IF

// Lógica de control del compresor
IF btnParo THEN
    comp := FALSE; // Parar el compresor
ELSIF NOT comp THEN
    // Arrancar el compresor solo si se presiona btnMarcha y todos los permisivos están bien
    IF btnMarcha AND NOT btnMarchaPrev AND causaBloqueo = 0 THEN
        comp := TRUE;
    END_IF
END_IF

// Actualizar el estado previo del botón de marcha
btnMarchaPrev := btnMarcha;
END_FUNCTION_BLOCK
```

Este código implementa la lógica de control de un compresor conforme a los requisitos especificados, utilizando el estándar IEC 61131-3 en Structured Text.