(* DOBLE DE PRUEBA B7/TelerruptorManual - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 2 *)
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
    prev : BOOL;
END_VAR
IF modoAuto THEN
    bomba := nivelBajo;
ELSIF btnManual AND NOT prev THEN
    bomba := NOT bomba;
END_IF
prev := btnManual;
END_PROGRAM
