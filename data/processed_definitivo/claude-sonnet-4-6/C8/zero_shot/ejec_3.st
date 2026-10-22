FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Señal de nivel alto *)
END_VAR

VAR_OUTPUT
    valvula : BOOL; (* Salida hacia la válvula *)
END_VAR

VAR
    T1 : TON; (* Temporizador a la conexión, 5 segundos *)
END_VAR

(* Rama 1: nivelAlto activa el temporizador T1 con PT = 5 s *)
T1(IN := nivelAlto, PT := T#5S);

(* Rama 2: cuando T1 expira (Q = TRUE), se activa la válvula *)
valvula := T1.Q;