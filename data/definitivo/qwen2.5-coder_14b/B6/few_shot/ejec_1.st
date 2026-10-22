FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condicion de alarma *)
END_VAR
VAR_OUTPUT
    lampara : BOOL; (* Lámpara de la baliza *)
END_VAR
VAR
    tParpadeo : TP; (* Temporizador para el parpadeo *)
    estado : BOOL; (* Estado actual de la lámpara *)
END_VAR

(* Inicialización del temporizador *)
IF alarma THEN
    tParpadeo(IN := TRUE, PT := T#1S);
    estado := tParpadeo.Q;
    lampara := estado;
ELSE
    lampara := FALSE;
END_IF;
END_FUNCTION_BLOCK