(* DOBLE DE PRUEBA B1/RearranqueTrasEmergencia - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 6 *)
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL;
    btnParo : BOOL;
    btnEmerg : BOOL;
END_VAR
VAR_OUTPUT
    motorOn : BOOL;
END_VAR
VAR
    nada : BOOL;
END_VAR
IF btnParo OR btnEmerg THEN
    motorOn := FALSE;
ELSIF btnMarcha THEN
    motorOn := TRUE;
END_IF
END_FUNCTION_BLOCK
