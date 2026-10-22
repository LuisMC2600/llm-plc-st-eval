(* DOBLE DE PRUEBA B2/Correcta - NO ES CORPUS. Esperado: veredicto 1 *)
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
valvula := t.Q;
END_FUNCTION_BLOCK
