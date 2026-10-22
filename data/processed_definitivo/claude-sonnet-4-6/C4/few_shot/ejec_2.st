FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  (* Señal de demanda de caudal: TRUE = se requiere bombeo *)
    falla1  : BOOL;  (* Fallo detectado en bomba 1: TRUE = bomba 1 en falla *)
    falla2  : BOOL;  (* Fallo detectado en bomba 2: TRUE = bomba 2 en falla *)
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; (* Orden de marcha a bomba 1 *)
    bomba2   : BOOL; (* Orden de marcha a bomba 2 *)
    almFalla : BOOL; (* Alarma activa: la bomba de turno tiene falla *)
END_VAR
VAR
    turno : BOOL;   (* Bit de alternancia: FALSE = turno de bomba 2, TRUE = turno de bomba 1 *)
    fDem  : R_TRIG; (* Detector de flanco ascendente sobre la señal de demanda *)
END_VAR

(* ── Detección de flanco ascendente de demanda ──────────────────────────────
   fDem.Q vale TRUE únicamente durante el ciclo en que demanda pasa de 0 a 1. *)
fDem(CLK := demanda);

(* ── Alternancia de turno ────────────────────────────────────────────────────
   Cada nuevo arranque (flanco de demanda) invierte el bit de turno,
   asegurando que las bombas se usen de forma alternada y equitativa. *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* ── Lógica de arranque y alarma ─────────────────────────────────────────── *)
IF demanda THEN

    IF turno THEN
        (* Turno de bomba 1 como unidad prioritaria *)
        bomba1   := NOT falla1;          (* Arranca bomba 1 si no tiene falla *)
        bomba2   := falla1 AND NOT falla2; (* Bomba 2 entra solo si bomba 1 falla y bomba 2 está sana *)
        almFalla := falla1;              (* Alarma si la unidad prioritaria (bomba 1) está en falla *)
    ELSE
        (* Turno de bomba 2 como unidad prioritaria *)
        bomba2   := NOT falla2;          (* Arranca bomba 2 si no tiene falla *)
        bomba1   := falla2 AND NOT falla1; (* Bomba 1 entra solo si bomba 2 falla y bomba 1 está sana *)
        almFalla := falla2;              (* Alarma si la unidad prioritaria (bomba 2) está en falla *)
    END_IF

ELSE
    (* Sin demanda: apagado total y alarma silenciada *)
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;
END_IF

END_FUNCTION_BLOCK