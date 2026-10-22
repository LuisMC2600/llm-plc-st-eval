(* DOBLE DE PRUEBA B1/EmergenciaNoDomina - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 5 *)
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
IF btnMarcha THEN
    motorOn := TRUE;
ELSIF btnParo OR btnEmerg THEN
    motorOn := FALSE;
END_IF
END_FUNCTION_BLOCK
