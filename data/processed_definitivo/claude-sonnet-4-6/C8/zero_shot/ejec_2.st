FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto *)
END_VAR

VAR_OUTPUT
    valvula : BOOL; (* Bobina de la válvula *)
END_VAR

VAR
    T1 : TON; (* Temporizador a la conexión, retardo a la conexión *)
END_VAR

(* -------------------------------------------------------
   Rama 1: nivelAlto activa el temporizador T1 (TON, PT = 5 s)
   Rama 2: T1.Q activa la bobina valvula
   ------------------------------------------------------- *)

(* Rama 1 - Temporizador TON *)
T1(IN := nivelAlto, PT := T#5S);

(* Rama 2 - Bobina valvula *)
valvula := T1.Q;
END_FUNCTION_BLOCK