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
    estado : INT := 0; (* Estado del sistema: 0 - detenido, 1 - bomba1 principal, 2 - bomba2 principal *)
    demandaAnterior : BOOL := FALSE; (* Estado anterior de la demanda *)
END_VAR

(* Cambio de estado en la transición de FALSE a TRUE de demanda *)
IF demanda AND NOT demandaAnterior THEN
    estado := (estado + 1) MOD 3;
END_IF

(* Asignación de bombas según el estado *)
CASE estado OF
    0: (* Detenido *)
        bomba1 := FALSE;
        bomba2 := FALSE;
    1: (* Bomba1 principal *)
        bomba1 := NOT falla1;
        bomba2 := falla1 AND NOT falla2;
    2: (* Bomba2 principal *)
        bomba1 := falla2 AND NOT falla1;
        bomba2 := NOT falla2;
END_CASE

(* Alarma de falla de la bomba principal *)
almFalla := (estado = 1 AND falla1) OR (estado = 2 AND falla2);

(* Actualización del estado anterior de la demanda *)
demandaAnterior := demanda;
END_FUNCTION_BLOCK