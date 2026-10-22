FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Valvula de drenaje *)
END_VAR
VAR
    tRetardo : TON; (* Temporizador de retardo a la conexion *)
END_VAR

(* Retardo de 5 s para abrir la valvula; cierra de inmediato al desactivarse el sensor *)
tRetardo(IN := nivelAlto, PT := T#5S);
valvula := tRetardo.Q;
END_FUNCTION_BLOCK