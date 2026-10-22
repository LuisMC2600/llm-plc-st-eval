(* DOBLE DE PRUEBA A4/Sobrepaso - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 0 *)
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;
    paroRapido : BOOL;
    ciclo : TIME;
END_VAR
VAR_OUTPUT
    CVvel : REAL;
END_VAR
VAR
    d : REAL;
    obj : REAL;
    bajada : REAL;
    llego : BOOL;
END_VAR
d := TIME_TO_REAL(ciclo) / 1000.0;
IF paroRapido THEN
    obj := 0.0;
    bajada := 40.0;
ELSE
    obj := SPvel;
    bajada := 20.0;
END_IF
IF CVvel < obj THEN
    CVvel := CVvel + 10.0 * d;
ELSIF CVvel > obj THEN
    CVvel := CVvel - bajada * d;
END_IF
END_FUNCTION_BLOCK
