(* DOBLE DE PRUEBA I7/RespaldoEnclavado - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 7 *)
FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL;
    falla1 : BOOL;
    falla2 : BOOL;
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;
    bomba2 : BOOL;
    almFalla : BOOL;
END_VAR
VAR
    turno : BOOL;
    fDem : R_TRIG;
    enResp : BOOL;
END_VAR
fDem(CLK := demanda);
IF fDem.Q THEN
    turno := NOT turno;
END_IF
IF NOT demanda THEN
    enResp := FALSE;
ELSIF (turno AND falla1) OR (NOT turno AND falla2) THEN
    enResp := TRUE;
END_IF
IF NOT demanda THEN
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
ELSIF enResp THEN
    IF turno THEN
        bomba1 := FALSE;
        bomba2 := NOT falla2;
        almFalla := falla1;
    ELSE
        bomba2 := FALSE;
        bomba1 := NOT falla1;
        almFalla := falla2;
    END_IF
ELSE
        IF turno THEN
            bomba1 := NOT falla1;
            bomba2 := falla1 AND NOT falla2;
            almFalla := falla1;
        ELSE
            bomba2 := NOT falla2;
            bomba1 := falla2 AND NOT falla1;
            almFalla := falla2;
        END_IF
END_IF
END_FUNCTION_BLOCK
