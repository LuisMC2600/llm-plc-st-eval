FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto del tanque *)
END_VAR

VAR_OUTPUT
    valvula : BOOL; (* TRUE = válvula abierta, FALSE = válvula cerrada *)
END_VAR

VAR
    tonRetardo : TON; (* Temporizador de retardo para confirmación de nivel alto *)
END_VAR

(*
    Control de válvula de drenaje:
    - La válvula abre cuando nivelAlto permanece activo durante 5 segundos continuos.
    - La válvula cierra de inmediato si nivelAlto deja de estar activo.
*)

(* Activar temporizador solo mientras nivelAlto esté activo *)
tonRetardo(IN := nivelAlto, PT := T#5S);

(* La válvula abre cuando el temporizador completa los 5 segundos *)
(* Si nivelAlto cae, tonRetardo.Q se resetea de inmediato y la válvula cierra *)
valvula := tonRetardo.Q;

END_FUNCTION_BLOCK