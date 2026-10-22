(* DOBLE DE PRUEBA B5/TiempoLargo - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 3 *)
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
t(IN := quemadorOn, PT := T#60S);
ventilador := t.Q;
END_FUNCTION_BLOCK
