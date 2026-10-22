```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto del tanque *)
END_VAR

VAR_OUTPUT
    valvula : BOOL; (* TRUE = válvula abierta, FALSE = válvula cerrada *)
END_VAR

VAR
    tonRetardo : TON; (* Temporizador de retardo para confirmar nivel alto *)
END_VAR

(* ---------------------------------------------------------------
   Lógica de control:
   - El temporizador TON se habilita mientras nivelAlto esté activo.
   - Si nivelAlto se desactiva antes de 5 s, el temporizador se
     reinicia automáticamente (IN := FALSE).
   - Cuando nivelAlto permanece activo >= 5 s, tonRetardo.Q = TRUE
     y la válvula abre.
   - Si nivelAlto cae, la válvula cierra de inmediato (sin retardo).
--------------------------------------------------------------- *)

(* Llamada al temporizador: activo solo mientras nivelAlto sea TRUE *)
tonRetardo(
    IN := nivelAlto,
    PT := T#5S
);

(* La válvula abre cuando el temporizador confirma 5 s continuos de nivel alto.
   Si nivelAlto cae, tonRetardo.Q vuelve a FALSE de inmediato porque
   el temporizador se reinicia, cerrando la válvula sin retardo. *)
valvula := tonRetardo.Q;
```