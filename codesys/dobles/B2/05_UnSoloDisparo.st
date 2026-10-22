(* DOBLE DE PRUEBA B2/UnSoloDisparo - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 4 *)
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL;
END_VAR
VAR_OUTPUT
    valvula : BOOL;
END_VAR
VAR
    t : TON;
    yaAbrio : BOOL;
END_VAR
t(IN := nivelAlto, PT := T#5S);
IF t.Q AND NOT yaAbrio THEN
    valvula := TRUE;
    yaAbrio := TRUE;
END_IF
IF NOT nivelAlto THEN
    valvula := FALSE;
END_IF
END_FUNCTION_BLOCK
