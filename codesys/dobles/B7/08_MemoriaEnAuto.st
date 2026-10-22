(* DOBLE DE PRUEBA B7/MemoriaEnAuto - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 5 *)
FUNCTION_BLOCK SelBomba
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
    bomba := bomba OR nivelBajo;
ELSE
    bomba := btnManual;
END_IF
END_FUNCTION_BLOCK
