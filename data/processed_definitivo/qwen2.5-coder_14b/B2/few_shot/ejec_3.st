FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto *)
END_VAR
VAR_OUTPUT
    valvula : BOOL; (* Válvula de drenaje *)
END_VAR
VAR
    tNivel : TP; (* Temporizador para el nivel alto *)
END_VAR

(* Temporizador que se activa cuando el nivel está alto *)
tNivel(IN := nivelAlto, PT := T#5S);

(* La válvula se abre si el temporizador ha expirado *)
valvula := tNivel.Q;

(* La válvula se cierra inmediatamente si el nivel deja de estar alto *)
IF NOT nivelAlto THEN
    valvula := FALSE;
END_IF
END_FUNCTION_BLOCK