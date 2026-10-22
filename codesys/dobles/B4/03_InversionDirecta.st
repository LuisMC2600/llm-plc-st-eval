(* DOBLE DE PRUEBA B4/InversionDirecta - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 3 *)
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
ELSIF btnFwd THEN
    fwd := TRUE;
    rev := FALSE;
ELSIF btnRev THEN
    rev := TRUE;
    fwd := FALSE;
END_IF
END_FUNCTION_BLOCK
