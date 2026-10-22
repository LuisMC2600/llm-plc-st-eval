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
    marchaAnterior : BOOL; // Estado anterior del botón de marcha
    paroAnterior : BOOL; // Estado anterior del botón de paro
    permisivoCumplido : BOOL; // Indica si se cumplen todos los permisivos
END_VAR

// Inicialización del temporizador
IF NOT timerOilOk.Q THEN
    timerOilOk(IN := FALSE, PT := T#3S);
END_IF

// Detectar transición de botón de marcha
IF btnMarcha AND NOT marchaAnterior THEN
    timerOilOk(IN := pOilOk);
END_IF

// Detectar transición de botón de paro
IF btnParo AND NOT paroAnterior THEN
    comp := FALSE;
END_IF

// Actualizar estado de botones
marchaAnterior := btnMarcha;
paroAnterior := btnParo;

// Verificar permisivos
permisivoCumplido := pOilOk AND tempOk AND sinAlm AND timerOilOk.Q;

// Determinar causa de bloqueo
IF NOT pOilOk THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF

// Control de arranque y paro
IF btnParo THEN
    comp := FALSE;
ELSEIF btnMarcha AND permisivoCumplido THEN
    comp := TRUE;
END_IF
END_FUNCTION_BLOCK