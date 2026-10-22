(* DOBLE DE PRUEBA B7/NivelInvertido - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 4 *)
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;
    btnManual : BOOL;
    nivelBajo : BOOL;
END_VAR
IF modoAuto THEN
    SelBomba := NOT nivelBajo;
ELSE
    SelBomba := btnManual;
END_IF
END_FUNCTION
