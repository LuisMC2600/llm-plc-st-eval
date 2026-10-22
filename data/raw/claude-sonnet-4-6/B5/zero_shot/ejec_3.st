```pascal
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Señal del quemador: TRUE = encendido *)
END_VAR

VAR_OUTPUT
    ventilador : BOOL; (* Salida del ventilador: TRUE = funcionando *)
END_VAR

VAR
    tonPostApagado : TON;  (* Temporizador de retardo al apagado *)
END_VAR

(*
    Lógica:
    - Si el quemador está encendido, el ventilador funciona y el temporizador se mantiene reseteado.
    - Al apagarse el quemador, el temporizador comienza a contar 30 segundos.
    - Cuando el temporizador completa los 30 segundos (Q = TRUE), el ventilador se detiene.
*)

(* Activar temporizador solo cuando el quemador está apagado *)
tonPostApagado(
    IN  := NOT quemadorOn,
    PT  := T#30S
);

(* El ventilador funciona si el quemador está encendido
   O si el temporizador aún no ha completado los 30 segundos *)
ventilador := quemadorOn OR NOT tonPostApagado.Q;

END_FUNCTION_BLOCK
```