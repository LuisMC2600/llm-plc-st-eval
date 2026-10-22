FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condicion de alarma *)
END_VAR
VAR_OUTPUT
    lampara : BOOL; (* Lampara de la baliza *)
END_VAR
VAR
    tEncendido : TON; (* Temporizador de fase encendida *)
    tApagado : TON; (* Temporizador de fase apagada *)
END_VAR

(* Ciclo de parpadeo: 1s encendido, 1s apagado mientras la alarma este activa *)
tEncendido(IN := alarma AND NOT tApagado.Q, PT := T#1S);
tApagado(IN := tEncendido.Q, PT := T#1S);

(* La lampara enciende inmediatamente con la alarma y alterna su estado cada segundo *)
lampara := alarma AND NOT tEncendido.Q;
END_FUNCTION_BLOCK