FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condicion de alarma *)
END_VAR
VAR_OUTPUT
    lampara : BOOL; (* Lampara de la baliza *)
END_VAR
VAR
    tOn : TON; (* Temporizador de fase encendida *)
    tOff : TON; (* Temporizador de fase apagada *)
END_VAR

(* Generador de intermitencia: 1s ON y 1s OFF mientras la alarma este activa *)
tOn(IN := alarma AND NOT tOff.Q, PT := T#1S);
tOff(IN := tOn.Q, PT := T#1S);

(* La lampara se enciende inmediatamente con la alarma y alterna su estado *)
lampara := alarma AND NOT tOn.Q;
END_FUNCTION_BLOCK