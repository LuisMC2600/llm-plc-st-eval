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
    (* Estados internos del bloque *)
    stateFwd : BOOL; (* Estado interno: motor en marcha horaria *)
    stateRev : BOOL; (* Estado interno: motor en marcha antihoraria *)
END_VAR

(*
    Lógica de control:
    - btnParo detiene el motor en cualquier estado (prioridad máxima).
    - btnFwd arranca en sentido horario SOLO si el motor está parado.
    - btnRev arranca en sentido antihorario SOLO si el motor está parado.
    - El enclavamiento (interlock) impide que fwd y rev sean TRUE simultáneamente.
*)

(* 1. Paro con prioridad máxima *)
IF btnParo THEN
    stateFwd := FALSE;
    stateRev := FALSE;

(* 2. Arranque horario: solo si el motor está completamente parado *)
ELSIF btnFwd AND NOT stateRev THEN
    stateFwd := TRUE;

(* 3. Arranque antihorario: solo si el motor está completamente parado *)
ELSIF btnRev AND NOT stateFwd THEN
    stateRev := TRUE;
END_IF;

(* 4. Asignación de salidas con interlock hardware por seguridad *)
fwd := stateFwd AND NOT stateRev;
rev := stateRev AND NOT stateFwd;

END_FUNCTION_BLOCK