FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Entrada que indica el nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Salida que controla la válvula
END_VAR

VAR
    T1 : TON; // Temporizador de tipo TON
END_VAR

// Inicialización del temporizador T1 con un tiempo preestablecido de 5 segundos
T1.PT := T#5S;

// Rama 1: Si nivelAlto es verdadero, arranca el temporizador T1
IF nivelAlto THEN
    T1(IN := TRUE);
ELSE
    T1(IN := FALSE);
END_IF;

// Rama 2: Si el temporizador T1 ha terminado, activa la válvula
valvula := T1.Q;