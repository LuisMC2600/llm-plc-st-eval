(* DOBLE DE PRUEBA B4/CarreraDeInterlock - NO ES CORPUS. Esperado: veredicto 2 *)
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
    fwdPrev : BOOL;
    revPrev : BOOL;
END_VAR
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;
ELSE
    IF btnFwd AND NOT revPrev THEN
        fwd := TRUE;
    END_IF
    IF btnRev AND NOT fwdPrev THEN
        rev := TRUE;
    END_IF
END_IF
fwdPrev := fwd;
revPrev := rev;
END_FUNCTION_BLOCK
