```pascal
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Señal del quemador: TRUE = encendido *)
END_VAR
VAR_OUTPUT
    ventilador : BOOL; (* Salida del ventilador de enfriamiento *)
END_VAR
VAR
    tPostMarcha : TON; (* Temporizador de post-marcha al apagar quemador *)
END_VAR

(* Temporizador inicia cuando el quemador se apaga (flanco descendente) *)
(* IN = NOT quemadorOn: empieza a contar en cuanto el quemador se detiene *)
tPostMarcha(IN := NOT quemadorOn, PT := T#30S);

(* El ventilador funciona mientras el quemador este encendido
   o mientras el temporizador de post-marcha no haya concluido *)
ventilador := quemadorOn OR NOT tPostMarcha.Q;
END_FUNCTION_BLOCK
```