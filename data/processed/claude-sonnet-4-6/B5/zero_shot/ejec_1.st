FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; (* Señal del quemador: TRUE = encendido *)
END_VAR

VAR_OUTPUT
    ventilador : BOOL; (* Salida del ventilador: TRUE = funcionando *)
END_VAR

VAR
    tPostEnfriamiento : TON;  (* Temporizador de post-enfriamiento *)
END_VAR

(*
    Lógica:
    - Si el quemador está encendido, el ventilador funciona y el temporizador se mantiene reseteado.
    - Al apagarse el quemador, el temporizador inicia y el ventilador sigue funcionando.
    - Transcurridos 30 s, el temporizador expira y el ventilador se detiene.
*)

(* Activar temporizador solo cuando el quemador está apagado *)
tPostEnfriamiento(
    IN  := NOT quemadorOn,
    PT  := T#30S
);

(* El ventilador funciona si el quemador está ON o si el temporizador aún no expiró *)
ventilador := quemadorOn OR NOT tPostEnfriamiento.Q;