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
    causaBloqueo : INT; // Causa del bloqueo
END_VAR

VAR
    timerOilOk : TON; // Temporizador para la presión de aceite
    marchaAnterior : BOOL; // Estado anterior del botón de marcha
    paroAnterior : BOOL; // Estado anterior del botón de paro
    permisivoCumplido : BOOL; // Indica si todos los permisivos están cumplidos
    estadoMarcha : BOOL; // Estado actual del compresor
END_VAR

// Inicialización del temporizador
IF NOT timerOilOk.Q THEN
    timerOilOk(IN := FALSE, PT := T#3S);
END_IF;

// Actualización de estados anteriores
marchaAnterior := btnMarcha;
paroAnterior := btnParo;

// Lógica de paro
IF btnParo AND NOT paroAnterior THEN
    comp := FALSE;
    estadoMarcha := FALSE;
END_IF;

// Lógica de arranque
IF btnMarcha AND NOT marchaAnterior THEN
    timerOilOk(IN := pOilOk);
    permisivoCumplido := pOilOk AND tempOk AND sinAlm;
    IF permisivoCumplido THEN
        comp := TRUE;
        estadoMarcha := TRUE;
    END_IF;
END_IF;

// Mantener el compresor en marcha si ya está arrancado
IF estadoMarcha THEN
    comp := TRUE;
ELSE
    comp := FALSE;
END_IF;

// Determinar la causa del bloqueo
IF NOT pOilOk THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF;

// Reiniciar el temporizador si la presión de aceite se pierde
IF NOT pOilOk THEN
    timerOilOk(IN := FALSE);
END_IF;

END_FUNCTION_BLOCK
```