(* DOBLE DE PRUEBA B5/TonEnVezDeTof - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 1 *)
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL;
END_VAR
VAR_OUTPUT
    ventilador : BOOL;
END_VAR
VAR
    t : TON;
END_VAR
t(IN := quemadorOn, PT := T#30S);
ventilador := t.Q;
END_FUNCTION_BLOCK
