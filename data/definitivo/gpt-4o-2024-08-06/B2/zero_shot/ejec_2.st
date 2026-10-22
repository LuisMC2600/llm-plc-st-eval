```pascal
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
```

Este código define un bloque de función `FB_Valvula` que controla la apertura y cierre de una válvula de drenaje basada en la entrada de un sensor de nivel alto. Utiliza un temporizador `TON` para asegurarse de que el nivel alto se mantenga durante 5 segundos antes de abrir la válvula. Si el nivel deja de ser alto, la válvula se cierra inmediatamente.