(* DOBLE DE PRUEBA B7/ModoInvertido - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 1 *)
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;
    btnManual : BOOL;
    nivelBajo : BOOL;
END_VAR
IF modoAuto THEN
    SelBomba := btnManual;
ELSE
    SelBomba := nivelBajo;
END_IF
END_FUNCTION
