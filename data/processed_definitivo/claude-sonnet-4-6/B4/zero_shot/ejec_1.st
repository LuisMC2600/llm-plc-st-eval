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
    - Nunca se permite cambio directo de sentido sin pasar por paro.
*)

(* ── 1. PARO: prioridad máxima ── *)
IF btnParo THEN
    fwd      := FALSE;
    rev      := FALSE;
    xRunning := FALSE;

(* ── 2. MARCHA HORARIA: solo si el motor está parado ── *)
ELSIF btnFwd AND NOT xRunning THEN
    fwd      := TRUE;
    rev      := FALSE;  (* Enclavamiento: rev siempre apagada *)
    xRunning := TRUE;

(* ── 3. MARCHA ANTIHORARIA: solo si el motor está parado ── *)
ELSIF btnRev AND NOT xRunning THEN
    rev      := TRUE;
    fwd      := FALSE;  (* Enclavamiento: fwd siempre apagada *)
    xRunning := TRUE;

(* ── 4. Sin pulsación relevante: mantener estado actual ── *)
END_IF;

(* ── 5. Enclavamiento de seguridad por hardware (doble seguro) ── *)
(* Garantiza que nunca ambas salidas estén activas, incluso ante  *)
(* corrupción de memoria o fallo lógico imprevisto.               *)
IF fwd AND rev THEN
    fwd      := FALSE;
    rev      := FALSE;
    xRunning := FALSE;
END_IF;

END_FUNCTION_BLOCK