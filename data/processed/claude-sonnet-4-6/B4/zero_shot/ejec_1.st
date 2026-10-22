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
    - btnParo detiene cualquier giro activo (prioridad máxima).
    - btnFwd activa giro horario SOLO si no hay giro antihorario activo.
    - btnRev activa giro antihorario SOLO si no hay giro horario activo.
    - Para invertir el sentido es obligatorio pasar por paro.
    - Las salidas fwd y rev nunca pueden ser TRUE simultáneamente.
*)

(* 1. Paro: tiene prioridad sobre todo *)
IF btnParo THEN
    stateFwd := FALSE;
    stateRev := FALSE;

(* 2. Marcha horaria: solo si el giro antihorario NO está activo *)
ELSIF btnFwd AND NOT stateRev THEN
    stateFwd := TRUE;

(* 3. Marcha antihoraria: solo si el giro horario NO está activo *)
ELSIF btnRev AND NOT stateFwd THEN
    stateRev := TRUE;
END_IF;

(* 4. Asignación de salidas con enclavamiento hardware por software *)
fwd := stateFwd AND NOT stateRev; (* Seguridad adicional: nunca ambas activas *)
rev := stateRev AND NOT stateFwd; (* Seguridad adicional: nunca ambas activas *)

END_FUNCTION_BLOCK