(* DOBLE DE PRUEBA I7/PrimeraEsB2 - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 1 *)
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
END_VAR
fDem(CLK := demanda);
IF fDem.Q THEN
    turno := NOT turno;
END_IF
IF demanda THEN
    IF NOT turno THEN
        bomba1 := NOT falla1;
        bomba2 := falla1 AND NOT falla2;
        almFalla := falla1;
    ELSE
        bomba2 := NOT falla2;
        bomba1 := falla2 AND NOT falla1;
        almFalla := falla2;
    END_IF
ELSE
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK
