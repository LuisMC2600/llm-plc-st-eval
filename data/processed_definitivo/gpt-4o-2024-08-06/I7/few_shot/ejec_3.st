FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Demanda de operación *)
    falla1 : BOOL;  (* Falla de la bomba 1 *)
    falla2 : BOOL;  (* Falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;  (* Estado de la bomba 1 *)
    bomba2 : BOOL;  (* Estado de la bomba 2 *)
    almFalla : BOOL; (* Alarma de falla *)
END_VAR
VAR
    principal : BOOL := TRUE; (* Indica si la bomba 1 es la principal *)
    demandaAnt : BOOL := FALSE; (* Estado anterior de la demanda *)
END_VAR

(* Detectar flanco de subida de la demanda *)
IF (demanda AND NOT demandaAnt) THEN
    (* Alternar la bomba principal en cada nueva demanda *)
    principal := NOT principal;
END_IF

(* Actualizar el estado anterior de la demanda *)
demandaAnt := demanda;

(* Lógica de control de bombas y alarma *)
IF demanda THEN
    IF principal THEN
        (* Bomba 1 es la principal *)
        IF NOT falla1 THEN
            bomba1 := TRUE;
            bomba2 := FALSE;
            almFalla := FALSE;
        ELSIF NOT falla2 THEN
            bomba1 := FALSE;
            bomba2 := TRUE;
            almFalla := TRUE;
        ELSE
            bomba1 := FALSE;
            bomba2 := FALSE;
            almFalla := TRUE;
        END_IF
    ELSE
        (* Bomba 2 es la principal *)
        IF NOT falla2 THEN
            bomba1 := FALSE;
            bomba2 := TRUE;
            almFalla := FALSE;
        ELSIF NOT falla1 THEN
            bomba1 := TRUE;
            bomba2 := FALSE;
            almFalla := TRUE;
        ELSE
            bomba1 := FALSE;
            bomba2 := FALSE;
            almFalla := TRUE;
        END_IF
    END_IF
ELSE
    (* Sin demanda, ambas bombas apagadas y sin alarma *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK