FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condición de alarma *)
END_VAR
VAR_OUTPUT
    lampara : BOOL; (* Lámpara de la baliza *)
END_VAR
VAR
    tParpadeo : TON; (* Temporizador de parpadeo *)
    estadoParpadeo : BOOL; (* Estado interno de parpadeo *)
END_VAR

(* Temporizador para controlar el parpadeo de la lámpara *)
tParpadeo(IN := alarma AND NOT tParpadeo.Q, PT := T#1S);

(* Alterna el estado de la lámpara cada segundo mientras hay alarma *)
IF alarma THEN
    IF tParpadeo.Q THEN
        estadoParpadeo := NOT estadoParpadeo;
        tParpadeo(IN := FALSE); (* Reinicia el temporizador *)
    END_IF;
    lampara := estadoParpadeo;
ELSE
    lampara := FALSE; (* Lámpara apagada sin alarma *)
    estadoParpadeo := FALSE; (* Reinicia el estado de parpadeo *)
END_IF;
END_FUNCTION_BLOCK