```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Contacto NA para activar el temporizador *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Bobina controlada por la salida del temporizador *)
END_VAR
VAR
    T1 : TON; (* Temporizador TON *)
END_VAR

(* Configuración del temporizador TON *)
T1(IN := nivelAlto, PT := T#5S);

(* La salida de la válvula se activa cuando el temporizador alcanza el tiempo preestablecido *)
valvula := T1.Q;
END_FUNCTION_BLOCK
```