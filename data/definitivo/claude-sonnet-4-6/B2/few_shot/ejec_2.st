```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto del tanque *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Valvula de drenaje: TRUE = abierta *)
END_VAR
VAR
    tRetardo : TON; (* Temporizador de retardo a la conexion *)
END_VAR

(* La valvula abre solo si el nivel alto se mantiene 5 s continuos.
   Si el nivel deja de estar alto, el temporizador se reinicia
   y la valvula cierra de inmediato. *)
tRetardo(IN := nivelAlto, PT := T#5S);
valvula := tRetardo.Q;
END_FUNCTION_BLOCK
```