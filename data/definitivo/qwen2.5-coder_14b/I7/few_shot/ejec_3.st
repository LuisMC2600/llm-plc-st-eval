FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Demanda de arranque *)
    falla1 : BOOL; (* Falla de la bomba 1 *)
    falla2 : BOOL; (* Falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL; (* Bomba principal *)
    bomba2 : BOOL; (* Bomba de respaldo *)
    almFalla : BOOL; (* Alarma de falla de la bomba principal *)
END_VAR
VAR
    estado : INT := 0; (* Estado actual: 0 = detenido, 1 = bomba1 principal, 2 = bomba2 principal *)
    demandaAnterior : BOOL := FALSE; (* Estado anterior de la demanda *)
END_VAR

(* Control de la alternancia de bombas y manejo de fallas *)
IF demanda THEN
    IF NOT demandaAnterior THEN
        (* Transición de FALSE a TRUE en demanda *)
        estado := (estado + 1) MOD 3;
        IF estado = 0 THEN
            estado := 1; (* Asegura que la primera demanda arranque bomba1 *)
        END_IF
    END_IF

    CASE estado OF
        1:
            IF falla1 THEN
                bomba1 := FALSE;
                bomba2 := NOT falla2;
                almFalla := NOT falla2;
            ELSE
                bomba1 := TRUE;
                bomba2 := FALSE;
                almFalla := FALSE;
            END_IF
        2:
            IF falla2 THEN
                bomba2 := FALSE;
                bomba1 := NOT falla1;
                almFalla := NOT falla1;
            ELSE
                bomba2 := TRUE;
                bomba1 := FALSE;
                almFalla := FALSE;
            END_IF
    END_CASE
ELSE
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF

(* Actualización del estado anterior de la demanda *)
demandaAnterior := demanda;
END_FUNCTION_BLOCK