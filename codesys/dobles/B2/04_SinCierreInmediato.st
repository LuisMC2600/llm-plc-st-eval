(* DOBLE DE PRUEBA B2/SinCierreInmediato - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 3 *)
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL;
END_VAR
VAR_OUTPUT
    valvula : BOOL;
END_VAR
VAR
    t : TON;
END_VAR
t(IN := nivelAlto, PT := T#5S);
IF t.Q THEN
    valvula := TRUE;
END_IF
END_FUNCTION_BLOCK
