```pascal
FUNCTION_BLOCK FB_Valvula
VAR
    nivelAlto : BOOL; // Entrada: indica si el nivel es alto
    valvula : BOOL;   // Salida: controla la válvula
    T1 : TON;         // Temporizador TON
END_VAR

// Inicialización del temporizador
T1(IN := nivelAlto, PT := T#5S);

// Asignación de la salida de la válvula
valvula := T1.Q;
```

Este código en Structured Text (ST) implementa el comportamiento descrito en el Ladder Diagram, utilizando un temporizador TON para controlar la salida `valvula` basada en la entrada `nivelAlto`.