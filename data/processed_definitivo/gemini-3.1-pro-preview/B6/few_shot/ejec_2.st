FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condicion de alarma *)
END_VAR
VAR_OUTPUT
    lampara : BOOL; (* Lampara de la baliza *)
END_VAR
VAR
    tonOn : TON; (* Temporizador de fase encendida *)
    tonOff : TON; (* Temporizador de fase apagada *)
END_VAR

(* Generador de pulsos: alterna entre temporizadores cada 1 segundo *)
tonOn(IN := alarma AND NOT tonOff.Q, PT := T#1S);
tonOff(IN := tonOn.Q, PT := T#1S);

(* La lampara enciende inmediatamente con la alarma y parpadea 1s ON / 1s OFF *)
lampara := alarma AND NOT tonOn.Q;
END_FUNCTION_BLOCK