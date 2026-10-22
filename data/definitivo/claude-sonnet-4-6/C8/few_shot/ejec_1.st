```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Contacto NA: activa el temporizador *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Bobina: activada tras retardo *)
END_VAR
VAR
    T1 : TON; (* Temporizador a la conexión, PT = 5 s *)
END_VAR

(* Rama 1: nivelAlto alimenta la entrada IN del TON T1 *)
T1(IN := nivelAlto, PT := T#5S);

(* Rama 2: la salida Q de T1 alimenta la bobina valvula *)
valvula := T1.Q;

END_FUNCTION_BLOCK
```