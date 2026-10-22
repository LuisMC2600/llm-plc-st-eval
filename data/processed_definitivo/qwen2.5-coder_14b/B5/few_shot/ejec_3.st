FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Estado del quemador *)
END_VAR
VAR_OUTPUT
    ventilador : BOOL; (* Estado del ventilador *)
END_VAR
VAR
    tApagado : TP; (* Temporizador para el apagado *)
END_VAR

(* El ventilador funciona mientras el quemador está encendido *)
IF quemadorOn THEN
    ventilador := TRUE;
    tApagado(IN := FALSE); (* Reinicia el temporizador *)
ELSE
    (* Si el quemador está apagado, el ventilador sigue funcionando durante 30 segundos *)
    tApagado(IN := TRUE, PT := T#30S);
    ventilador := tApagado.Q;
END_IF
END_FUNCTION_BLOCK