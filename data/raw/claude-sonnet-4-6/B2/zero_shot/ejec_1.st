```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto del tanque *)
END_VAR

VAR_OUTPUT
    valvula : BOOL; (* TRUE = válvula abierta, FALSE = válvula cerrada *)
END_VAR

VAR
    tonRetardo : TON; (* Temporizador on-delay de 5 segundos *)
END_VAR

(* -------------------------------------------------------
   Lógica de control:
   - El temporizador se habilita solo mientras nivelAlto
     esté activo de forma continua.
   - Si nivelAlto cae a FALSE, el temporizador se resetea
     inmediatamente (IN := FALSE) y la válvula cierra.
   - Cuando el temporizador completa T#5S (Q = TRUE),
     la válvula abre.
   ------------------------------------------------------- *)

(* Llamada al temporizador: se activa con nivelAlto *)
tonRetardo(
    IN := nivelAlto,   (* Habilita el conteo mientras nivel esté alto *)
    PT := T#5S         (* Tiempo de retardo requerido *)
);

(* La válvula abre cuando el temporizador completa los 5 s.
   Si nivelAlto cae, tonRetardo.Q vuelve FALSE de inmediato
   porque IN := FALSE resetea el bloque TON. *)
valvula := tonRetardo.Q;

END_FUNCTION_BLOCK
```