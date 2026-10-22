(* DOBLE DE PRUEBA B1/ParoInvertido - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 1 *)
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
IF btnEmerg OR NOT btnParo THEN
    motorOn := FALSE;
ELSIF btnMarcha THEN
    motorOn := TRUE;
END_IF
END_FUNCTION_BLOCK
