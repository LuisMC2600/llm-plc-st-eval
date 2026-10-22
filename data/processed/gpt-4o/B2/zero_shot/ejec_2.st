FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Entrada del sensor de nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Salida para controlar la válvula
END_VAR

VAR
    timerNivelAlto : TON; // Temporizador para el retardo de 5 segundos
END_VAR

// Inicialización del temporizador
timerNivelAlto(IN := nivelAlto, PT := T#5S);

// Lógica de control de la válvula
IF timerNivelAlto.Q THEN
    valvula := TRUE; // Abre la válvula si el nivel alto se mantiene por 5 segundos
ELSE
    valvula := FALSE; // Cierra la válvula si el nivel no es alto
END_IF

END_FUNCTION_BLOCK