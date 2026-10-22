FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Estado del quemador *)
END_VAR
VAR_OUTPUT
    ventilador : BOOL; (* Estado del ventilador *)
END_VAR
VAR
    tApagado : TP; (* Temporizador para el apagado *)
    estadoVentilador : BOOL; (* Estado interno del ventilador *)
END_VAR

(* Si el quemador está encendido, el ventilador también lo está *)
IF quemadorOn THEN
    estadoVentilador := TRUE;
    tApagado(IN := FALSE); (* Reinicia el temporizador *)
ELSE
    (* Si el quemador está apagado, el ventilador sigue encendido durante 30 segundos *)
    tApagado(IN := TRUE, PT := T#30S);
    estadoVentilador := tApagado.Q;
END_IF;

ventilador := estadoVentilador;
END_FUNCTION_BLOCK