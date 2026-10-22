(* DOBLE DE PRUEBA B5/SinRetardo - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 2 *)
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL;
END_VAR
VAR_OUTPUT
    ventilador : BOOL;
END_VAR
VAR
    nada : BOOL;
END_VAR
ventilador := quemadorOn;
END_FUNCTION_BLOCK
