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