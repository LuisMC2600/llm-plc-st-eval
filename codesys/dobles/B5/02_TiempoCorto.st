(* DOBLE DE PRUEBA B5/TiempoCorto - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 2 *)
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL;
END_VAR
VAR_OUTPUT
    ventilador : BOOL;
END_VAR
VAR
    t : TOF;
END_VAR
t(IN := quemadorOn, PT := T#10S);
ventilador := t.Q;
END_FUNCTION_BLOCK
