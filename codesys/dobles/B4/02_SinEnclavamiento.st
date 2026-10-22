(* DOBLE DE PRUEBA B4/SinEnclavamiento - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 2 *)
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
fwd := btnFwd AND NOT btnParo AND NOT btnRev;
rev := btnRev AND NOT btnParo AND NOT btnFwd;
END_FUNCTION_BLOCK
