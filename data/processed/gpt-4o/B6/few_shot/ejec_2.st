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

(* Temporizador para el parpadeo de la lámpara *)
tParpadeo(IN := alarma AND NOT tParpadeo.Q, PT := T#1S);

(* Alterna el estado de parpadeo cada segundo mientras la alarma está activa *)
IF tParpadeo.Q THEN
    estadoParpadeo := NOT estadoParpadeo;
    tParpadeo(IN := FALSE); (* Reinicia el temporizador *)
END_IF

(* La lámpara parpadea si hay alarma, de lo contrario permanece apagada *)
lampara := alarma AND estadoParpadeo;
END_FUNCTION_BLOCK