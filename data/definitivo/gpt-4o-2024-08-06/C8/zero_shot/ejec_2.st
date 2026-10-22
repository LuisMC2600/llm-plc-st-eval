```pascal
FUNCTION_BLOCK FB_Valvula
VAR
    nivelAlto : BOOL; // Entrada: indica si el nivel es alto
    valvula : BOOL;   // Salida: controla la válvula
    T1 : TON;         // Temporizador TON
END_VAR

// Asignación del tiempo preestablecido del temporizador
T1(IN := nivelAlto, PT := T#5S);

// La salida de la válvula se activa si el temporizador ha alcanzado el tiempo preestablecido
valvula := T1.Q;
END_FUNCTION_BLOCK
```