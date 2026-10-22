```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Entrada del sensor de nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Salida para el control de la válvula
END_VAR

VAR
    timer : TON; // Temporizador para el retardo de 5 segundos
END_VAR

// Inicialización del temporizador
timer(IN := nivelAlto, PT := T#5S);

// Lógica de control de la válvula
IF timer.Q THEN
    valvula := TRUE; // Abre la válvula si el temporizador ha alcanzado el tiempo preestablecido
ELSE
    valvula := FALSE; // Cierra la válvula si el nivel alto no está activo o no ha alcanzado los 5 segundos
END_IF
END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Valvula` que controla la apertura y cierre de una válvula de drenaje basada en el estado de un sensor de nivel alto. Utiliza un temporizador `TON` para asegurar que el nivel alto esté activo durante 5 segundos antes de abrir la válvula. La válvula se cierra inmediatamente si el nivel alto deja de estar activo.