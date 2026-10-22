FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; (* Botón marcha horaria *)
    btnRev  : BOOL; (* Botón marcha antihoraria *)
    btnParo : BOOL; (* Botón paro *)
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
    - btnParo detiene el motor (prioridad máxima).
    - btnFwd activa fwd solo si el motor está parado (rev = FALSE).
    - btnRev activa rev solo si el motor está parado (fwd = FALSE).
    - Nunca se permite activar fwd y rev simultáneamente.
    - Para invertir el giro es obligatorio pasar por paro.
*)

(* 1. Paro con prioridad máxima *)
IF btnParo THEN
    fwd      := FALSE;
    rev      := FALSE;
    xRunning := FALSE;

(* 2. Marcha horaria: solo si el motor está parado *)
ELSIF btnFwd AND NOT xRunning THEN
    fwd      := TRUE;
    rev      := FALSE;  (* Enclavamiento: garantiza rev = FALSE *)
    xRunning := TRUE;

(* 3. Marcha antihoraria: solo si el motor está parado *)
ELSIF btnRev AND NOT xRunning THEN
    rev      := TRUE;
    fwd      := FALSE;  (* Enclavamiento: garantiza fwd = FALSE *)
    xRunning := TRUE;

(* 4. Sin pulsación relevante: mantener estado actual *)
END_IF;