FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Contacto NA *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Bobina *)
END_VAR
VAR
    T1 : TON; (* Temporizador *)
END_VAR

(* Inicialización del temporizador *)
IF nivelAlto THEN
    T1(IN := TRUE, PT := T#5S);
ELSE
    T1(IN := FALSE);
END_IF;

(* La salida del temporizador alimenta la bobina valvula *)
valvula := T1.Q;
END_FUNCTION_BLOCK