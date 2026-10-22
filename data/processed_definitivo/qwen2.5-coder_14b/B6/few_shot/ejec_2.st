FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condición de alarma *)
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
    estado := NOT estado; (* Cambia el estado de la lámpara *)
ELSE
    tParpadeo(IN := FALSE);
    estado := FALSE; (* Apaga la lámpara *)
END_IF;

(* Asigna el estado de la lámpara *)
lampara := estado AND alarma;
END_FUNCTION_BLOCK