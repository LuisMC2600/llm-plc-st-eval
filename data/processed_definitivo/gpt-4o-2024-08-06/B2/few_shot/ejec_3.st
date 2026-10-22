FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Estado de la válvula de drenaje *)
END_VAR
VAR
    tRetardo : TON; (* Temporizador de retardo *)
END_VAR

(* La válvula se abre si el nivel alto se mantiene durante 5 segundos *)
tRetardo(IN := nivelAlto, PT := T#5S);
valvula := tRetardo.Q;
END_FUNCTION_BLOCK