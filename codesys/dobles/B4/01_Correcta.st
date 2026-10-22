(* DOBLE DE PRUEBA B4/Correcta - NO ES CORPUS. Esperado: veredicto 1 *)
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;
    btnRev : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    fwd : BOOL;
    rev : BOOL;
END_VAR
VAR
    nada : BOOL;
END_VAR
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;
ELSE
    IF btnFwd AND NOT rev THEN
        fwd := TRUE;
    END_IF
    IF btnRev AND NOT fwd THEN
        rev := TRUE;
    END_IF
END_IF
END_FUNCTION_BLOCK
