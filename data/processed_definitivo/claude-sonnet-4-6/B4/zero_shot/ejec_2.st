FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; (* Botón marcha horaria *)
    btnRev  : BOOL; (* Botón marcha antihoraria *)
    btnParo : BOOL; (* Botón de paro *)
END_VAR

VAR_OUTPUT
    fwd : BOOL; (* Salida giro horario *)
    rev : BOOL; (* Salida giro antihorario *)
END_VAR

VAR
    (* Estado interno: TRUE = en marcha, FALSE = parado *)
    xRunning : BOOL := FALSE;
END_VAR

(*
    Lógica de control:
    - btnParo detiene el motor (prioridad alta).
    - btnFwd activa fwd solo si el motor está parado (xRunning = FALSE).
    - btnRev activa rev solo si el motor está parado (xRunning = FALSE).
    - Una vez en marcha, solo btnParo puede cambiar el estado.
    - fwd y rev nunca pueden estar activas simultáneamente.
*)

(* 1. Paro con prioridad máxima *)
IF btnParo THEN
    fwd      := FALSE;
    rev      := FALSE;
    xRunning := FALSE;

(* 2. Arranque en sentido horario: solo si el motor está parado *)
ELSIF btnFwd AND NOT xRunning THEN
    fwd      := TRUE;
    rev      := FALSE;  (* Interbloqueo: asegurar rev inactiva *)
    xRunning := TRUE;

(* 3. Arranque en sentido antihorario: solo si el motor está parado *)
ELSIF btnRev AND NOT xRunning THEN
    rev      := TRUE;
    fwd      := FALSE;  (* Interbloqueo: asegurar fwd inactiva *)
    xRunning := TRUE;

(* 4. Motor en marcha: mantener estado hasta recibir paro *)
(* No se hace nada; fwd/rev conservan su valor *)
END_IF;

(* 5. Interbloqueo de seguridad por hardware: nunca ambas activas *)
IF fwd AND rev THEN
    fwd      := FALSE;
    rev      := FALSE;
    xRunning := FALSE;
END_IF;

END_FUNCTION_BLOCK