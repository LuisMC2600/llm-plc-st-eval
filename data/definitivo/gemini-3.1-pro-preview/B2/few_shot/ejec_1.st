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

(* La valvula abre tras 5 s continuos de nivel alto y cierra de inmediato si baja *)
tRetardo(IN := nivelAlto, PT := T#5S);
valvula := tRetardo.Q;
END_FUNCTION_BLOCK