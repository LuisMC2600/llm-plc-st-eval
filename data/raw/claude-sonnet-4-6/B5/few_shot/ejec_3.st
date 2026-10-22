```pascal
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Señal del quemador: TRUE = encendido *)
END_VAR
VAR_OUTPUT
    ventilador : BOOL; (* Salida del ventilador de enfriamiento *)
END_VAR
VAR
    tPostMarcha : TOF; (* Temporizador de retardo a la desconexion *)
END_VAR

(* El ventilador funciona mientras el quemador este encendido        *)
(* y continua 30 s adicionales tras apagarse el quemador (post-marcha) *)
tPostMarcha(IN := quemadorOn, PT := T#30S);
ventilador := tPostMarcha.Q;
END_FUNCTION_BLOCK
```