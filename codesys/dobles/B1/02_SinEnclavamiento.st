(* DOBLE DE PRUEBA B1/SinEnclavamiento - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 2 *)
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
motorOn := btnMarcha AND NOT btnParo AND NOT btnEmerg;
END_FUNCTION_BLOCK
