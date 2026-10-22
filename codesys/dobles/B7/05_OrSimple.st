(* DOBLE DE PRUEBA B7/OrSimple - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 3 *)
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;
    btnManual : BOOL;
    nivelBajo : BOOL;
END_VAR
SelBomba := btnManual OR nivelBajo;
END_FUNCTION
