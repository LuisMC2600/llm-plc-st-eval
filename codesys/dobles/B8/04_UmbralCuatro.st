(* DOBLE DE PRUEBA B8/UmbralCuatro - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 4 *)
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
    nAperturas := 0;
ELSIF puertaAbierta AND NOT prev THEN
    nAperturas := nAperturas + 1;
END_IF
prev := puertaAbierta;
aviso := nAperturas >= 4;
END_FUNCTION_BLOCK
