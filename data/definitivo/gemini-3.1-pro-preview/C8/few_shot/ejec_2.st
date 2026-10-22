FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Contacto NA que inicia el temporizador *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Bobina activada por el temporizador *)
END_VAR
VAR
    T1 : TON; (* Temporizador a la conexion *)
END_VAR

(* Rama 1: Llamada al temporizador TON con PT de 5 segundos *)
T1(IN := nivelAlto, PT := T#5S);

(* Rama 2: La bobina se activa con la salida Q del temporizador *)
valvula := T1.Q;
END_FUNCTION_BLOCK