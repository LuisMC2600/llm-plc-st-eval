```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto del tanque *)
END_VAR

VAR_OUTPUT
    valvula : BOOL; (* TRUE = válvula abierta, FALSE = válvula cerrada *)
END_VAR

VAR
    tonRetardo : TON; (* Temporizador on-delay para confirmar nivel alto *)
END_VAR

(* ---------------------------------------------------------------
   Lógica de control:
   - El temporizador TON se habilita mientras nivelAlto esté activo.
   - Si nivelAlto permanece TRUE durante 5 s continuos, tonRetardo.Q
     se pone TRUE y la válvula abre.
   - Si nivelAlto cae a FALSE en cualquier momento, el temporizador
     se resetea (IN=FALSE) y la válvula cierra de inmediato.
--------------------------------------------------------------- *)

(* Llamada al temporizador: se activa solo si nivelAlto es TRUE *)
tonRetardo(
    IN  := nivelAlto,
    PT  := T#5S
);

(* La válvula abre cuando el temporizador confirma 5 s de nivel alto;
   cierra de inmediato si nivelAlto deja de estar activo *)
valvula := tonRetardo.Q;

END_FUNCTION_BLOCK
```