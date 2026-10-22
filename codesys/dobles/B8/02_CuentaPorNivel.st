(* DOBLE DE PRUEBA B8/CuentaPorNivel - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 1 *)
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
ELSIF puertaAbierta THEN
    nAperturas := nAperturas + 1;
END_IF
prev := puertaAbierta;
aviso := nAperturas >= 5;
END_FUNCTION_BLOCK
