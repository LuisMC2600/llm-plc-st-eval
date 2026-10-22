FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Contacto NA para activar el temporizador *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Bobina controlada por el temporizador *)
END_VAR
VAR
    T1 : TON; (* Temporizador TON *)
END_VAR

(* Configuración del temporizador *)
T1(IN := nivelAlto, PT := T#5S);

(* La salida del temporizador controla la bobina *)
valvula := T1.Q;
END_FUNCTION_BLOCK