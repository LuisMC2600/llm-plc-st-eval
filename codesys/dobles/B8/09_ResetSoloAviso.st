(* DOBLE DE PRUEBA B8/ResetSoloAviso - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 7 *)
FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL;
    reset : BOOL;
END_VAR
VAR_OUTPUT
    aviso : BOOL;
    nAperturas : INT;
END_VAR
VAR
    prev : BOOL;
END_VAR
IF reset THEN
    aviso := FALSE;
ELSIF puertaAbierta AND NOT prev THEN
    nAperturas := nAperturas + 1;
END_IF
prev := puertaAbierta;
IF NOT reset THEN
    aviso := nAperturas >= 5;
END_IF
END_FUNCTION_BLOCK
