(* DOBLE DE PRUEBA B7/CorrectaPRG - NO ES CORPUS. Esperado: veredicto 1 *)
PROGRAM SelBomba
VAR_INPUT
    modoAuto : BOOL;
    btnManual : BOOL;
    nivelBajo : BOOL;
END_VAR
VAR_OUTPUT
    bomba : BOOL;
END_VAR
VAR
    nada : BOOL;
END_VAR
IF modoAuto THEN
    bomba := nivelBajo;
ELSE
    bomba := btnManual;
END_IF
END_PROGRAM
