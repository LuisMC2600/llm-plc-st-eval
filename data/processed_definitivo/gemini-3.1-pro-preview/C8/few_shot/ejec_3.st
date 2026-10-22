FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Contacto NA que activa el temporizador *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Bobina de salida *)
END_VAR
VAR
    T1 : TON; (* Temporizador a la conexion *)
END_VAR

(* Rama 1: El contacto alimenta la entrada IN del temporizador TON *)
T1(IN := nivelAlto, PT := T#5S);

(* Rama 2: El contacto de la salida del temporizador alimenta la bobina *)
valvula := T1.Q;
END_FUNCTION_BLOCK