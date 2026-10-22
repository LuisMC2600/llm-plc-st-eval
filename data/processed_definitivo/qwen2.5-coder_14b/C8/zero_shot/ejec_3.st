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
    T1(IN := TRUE, PT := T#5S);
ELSE
    T1(IN := FALSE);
END_IF;

// La válvula se abre cuando el temporizador T1 ha terminado su cuenta
valvula := T1.Q;