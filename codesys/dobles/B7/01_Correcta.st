(* DOBLE DE PRUEBA B7/Correcta - NO ES CORPUS. Esperado: veredicto 1 *)
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;
    btnManual : BOOL;
    nivelBajo : BOOL;
END_VAR
IF modoAuto THEN
    SelBomba := nivelBajo;
ELSE
    SelBomba := btnManual;
END_IF
END_FUNCTION
