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
    tApagado(IN := FALSE); (* Reiniciar el temporizador *)
ELSE
    (* Si el quemador está apagado, iniciar el temporizador *)
    tApagado(IN := TRUE, PT := T#30S);
    (* Mantener el ventilador encendido mientras el temporizador no haya expirado *)
    estadoVentilador := tApagado.Q;
END_IF;

(* Asignar el estado interno del ventilador a la salida *)
ventilador := estadoVentilador;
END_FUNCTION_BLOCK