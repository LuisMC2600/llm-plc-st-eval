FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Contacto normalmente abierto que detecta el nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Bobina que controla la válvula
END_VAR

VAR
    T1 : TON; // Temporizador a la conexión (Timer On Delay)
END_VAR

// Rama 1: El contacto nivelAlto alimenta la entrada IN del temporizador T1
T1(IN := nivelAlto, PT := T#5S);

// Rama 2: El contacto normalmente abierto de T1.Q alimenta la bobina valvula
valvula := T1.Q;

END_FUNCTION_BLOCK