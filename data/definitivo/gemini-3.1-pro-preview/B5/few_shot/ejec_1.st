FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Estado del quemador *)
END_VAR
VAR_OUTPUT
    ventilador : BOOL; (* Ventilador de enfriamiento *)
END_VAR
VAR
    tRetardoApagado : TOF; (* Temporizador de retardo a la desconexion *)
END_VAR

(* El ventilador continua funcionando 30 s despues de que se apaga el quemador *)
tRetardoApagado(IN := quemadorOn, PT := T#30S);
ventilador := tRetardoApagado.Q;
END_FUNCTION_BLOCK