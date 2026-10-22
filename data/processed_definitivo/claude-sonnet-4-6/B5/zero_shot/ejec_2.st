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

(* -------------------------------------------------------
   Lógica:
   - Quemador ON  → ventilador ON, temporizador en reset.
   - Quemador OFF → temporizador inicia 30 s; ventilador
     permanece ON hasta que el temporizador expire.
   ------------------------------------------------------- *)

(* Activar temporizador solo cuando el quemador está apagado *)
tonPostApagado(
    IN  := NOT quemadorOn,  (* Cuenta mientras quemador esté OFF *)
    PT  := T#30S            (* Tiempo de post-ventilación *)
);

(* El ventilador funciona si el quemador está ON
   o si el temporizador aún no ha expirado *)
ventilador := quemadorOn OR NOT tonPostApagado.Q;

END_FUNCTION_BLOCK