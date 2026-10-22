FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Contacto normalmente abierto que activa el temporizador
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Bobina de salida
END_VAR

VAR
    T1 : TON; // Temporizador a la conexión (Timer On Delay)
END_VAR

// Rama 1: El estado de nivelAlto alimenta la entrada IN del temporizador T1 con PT de 5 segundos
T1(IN := nivelAlto, PT := T#5S);

// Rama 2: El contacto normalmente abierto T1.Q alimenta la bobina valvula
valvula := T1.Q;

END_FUNCTION_BLOCK