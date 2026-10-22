```pascal
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Estado del quemador *)
END_VAR
VAR_OUTPUT
    ventilador : BOOL; (* Estado del ventilador *)
END_VAR
VAR
    tRetraso : TON; (* Temporizador de retardo *)
END_VAR

(* El ventilador funciona mientras el quemador está encendido o durante 30 segundos adicionales después de apagarse *)
tRetraso(IN := NOT quemadorOn, PT := T#30S);
ventilador := quemadorOn OR tRetraso.Q;
END_FUNCTION_BLOCK
```