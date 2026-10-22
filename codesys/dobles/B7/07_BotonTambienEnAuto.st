(* DOBLE DE PRUEBA B7/BotonTambienEnAuto - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 6 *)
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;
    btnManual : BOOL;
    nivelBajo : BOOL;
END_VAR
IF modoAuto THEN
    SelBomba := nivelBajo OR btnManual;
ELSE
    SelBomba := btnManual;
END_IF
END_FUNCTION
