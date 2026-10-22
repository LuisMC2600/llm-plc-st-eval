```pascal
FUNCTION_BLOCK FB_Valvula
VAR
    nivelAlto : BOOL; // Entrada: indica si el nivel es alto
    valvula : BOOL;   // Salida: controla la válvula
    T1 : TON;         // Temporizador TON
END_VAR

// Inicialización del temporizador
T1(IN := nivelAlto, PT := T#5S);

// Control de la válvula basado en el temporizador
valvula := T1.Q;
END_FUNCTION_BLOCK
```

Este código en Structured Text (ST) implementa el comportamiento descrito en el Ladder Diagram, utilizando un temporizador TON y controlando la salida `valvula` según el estado del temporizador.