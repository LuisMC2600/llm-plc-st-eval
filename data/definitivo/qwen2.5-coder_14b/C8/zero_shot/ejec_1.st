```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Entrada que indica el nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Salida que controla la válvula
END_VAR

VAR
    T1 : TON; // Temporizador de retardo por encendido
END_VAR

// Inicialización del temporizador T1 con un tiempo preestablecido de 5 segundos
IF nivelAlto THEN
    T1(IN := nivelAlto, PT := T#5S);
END_IF;

// La válvula se activa cuando el temporizador T1 ha terminado
valvula := T1.Q;
```

Este código en Structured Text (ST) implementa el comportamiento descrito en el Ladder Diagram. La variable `nivelAlto` es la entrada que indica el nivel alto, y `valvula` es la salida que controla la válvula. El temporizador `T1` se configura con un tiempo preestablecido de 5 segundos (`T#5S`). La válvula se activa cuando el temporizador `T1` ha terminado su cuenta.