FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condición de activación de la alarma *)
END_VAR
VAR_OUTPUT
    lampara : BOOL; (* Estado de la baliza luminosa *)
END_VAR
VAR
    tonEncendido : TON; (* Temporizador para el ciclo de encendido *)
    tonApagado : TON;   (* Temporizador para el ciclo de apagado *)
END_VAR

(* El primer temporizador cuenta 1s mientras la alarma esté activa y el segundo no haya terminado *)
tonEncendido(IN := alarma AND NOT tonApagado.Q, PT := T#1S);

(* El segundo temporizador cuenta 1s después de que el primero termina *)
tonApagado(IN := tonEncendido.Q, PT := T#1S);

(* La lámpara se enciende inmediatamente con la alarma y se apaga al terminar el primer tiempo *)
lampara := alarma AND NOT tonEncendido.Q;

END_FUNCTION_BLOCK