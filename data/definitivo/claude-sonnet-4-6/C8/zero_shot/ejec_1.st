```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Señal de nivel alto *)
END_VAR

VAR_OUTPUT
    valvula : BOOL; (* Salida hacia la válvula *)
END_VAR

VAR
    T1 : TON; (* Temporizador a la conexión, retardo a la activación *)
END_VAR

(* -------------------------------------------------------
   Rama 1: nivelAlto activa el temporizador T1 (TON, PT=5s)
   Rama 2: cuando T1.Q=TRUE se activa la salida valvula
   ------------------------------------------------------- *)

(* Rama 1: equivalente al contacto NA nivelAlto -> TON T1 *)
T1(IN := nivelAlto, PT := T#5S);

(* Rama 2: equivalente al contacto NA T1.Q -> bobina valvula *)
valvula := T1.Q;
END_FUNCTION_BLOCK
```