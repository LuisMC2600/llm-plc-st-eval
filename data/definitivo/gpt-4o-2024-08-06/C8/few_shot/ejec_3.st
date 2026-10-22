```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Contacto NA que activa el temporizador *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Bobina activada por la salida del temporizador *)
END_VAR
VAR
    T1 : TON; (* Temporizador TON *)
END_VAR

(* Configuración del temporizador TON *)
T1(IN := nivelAlto, PT := T#5S);

(* La salida del temporizador activa la bobina *)
valvula := T1.Q;
END_FUNCTION_BLOCK
```