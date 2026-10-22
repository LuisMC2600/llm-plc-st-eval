```pascal
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL; // Presión de aceite correcta
    tempOk : BOOL; // Temperatura correcta
    sinAlm : BOOL; // Ausencia de alarmas
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL; // Botón de paro
END_VAR

VAR_OUTPUT
    comp : BOOL; // Salida del compresor
    causaBloqueo : INT; // Causa de bloqueo
END_VAR

VAR
    timerOilOk : TON; // Temporizador para presión de aceite
    estadoMarcha : BOOL; // Estado de marcha del compresor
    lastBtnMarcha : BOOL; // Estado anterior del botón de marcha
    lastBtnParo : BOOL; // Estado anterior del botón de paro
END_VAR

// Inicialización
IF NOT estadoMarcha THEN
    comp := FALSE;
    causaBloqueo := 0;
END_IF

// Actualización de estados de botones
IF btnMarcha <> lastBtnMarcha THEN
    lastBtnMarcha := btnMarcha;
END_IF

IF btnParo <> lastBtnParo THEN
    lastBtnParo := btnParo;
END_IF

// Paro del compresor por botón de paro o pérdida de permisivos
IF btnParo OR (estadoMarcha AND (NOT pOilOk OR NOT tempOk OR NOT sinAlm)) THEN
    comp := FALSE;
    estadoMarcha := FALSE;
END_IF

// Inicio del compresor por botón de marcha
IF NOT estadoMarcha AND btnMarcha AND pOilOk AND tempOk AND sinAlm THEN
    comp := TRUE;
    estadoMarcha := TRUE;
END_IF

// Control de la causa de bloqueo
IF NOT pOilOk THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF

// Temporizador para presión de aceite
timerOilOk(IN := pOilOk, PT := T#3S);
IF timerOilOk.Q THEN
    // Presión de aceite correcta durante 3 segundos
    // (No se necesita acción adicional aquí)
END_IF

END_FUNCTION_BLOCK
```