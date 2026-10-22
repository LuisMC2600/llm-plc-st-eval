(* DOBLE DE PRUEBA A6/IdxSinValidar - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 8 *)
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT;
    estadoSeguro : BOOL;
    cmdAuto : ARRAY[0..7] OF BOOL;
    cmdManual : ARRAY[0..7] OF BOOL;
    idxForzado : INT;
    valorForzado : BOOL;
    confirmarForzado : BOOL;
END_VAR
VAR_OUTPUT
    modoActivo : INT := 1;
    actuador : ARRAY[0..7] OF BOOL;
END_VAR
VAR
    forz : ARRAY[0..7] OF BOOL;
    prev : BOOL;
    flanco : BOOL;
    i : INT;
    selPrev : INT := 1;
END_VAR
IF estadoSeguro AND selector >= 0 AND selector <= 2 AND selector <> modoActivo THEN
    IF modoActivo = 2 THEN
        FOR i := 0 TO 7 DO
        forz[i] := FALSE;
    END_FOR
    END_IF
    modoActivo := selector;
END_IF
flanco := confirmarForzado AND NOT prev;
prev := confirmarForzado;
CASE modoActivo OF
    0:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR
    1:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR
ELSE
    IF NOT estadoSeguro THEN
        FOR i := 0 TO 7 DO
        forz[i] := FALSE;
    END_FOR
    ELSIF flanco THEN
        forz[LIMIT(0, idxForzado, 7)] := valorForzado;
    END_IF
    FOR i := 0 TO 7 DO
        actuador[i] := forz[i];
    END_FOR
END_CASE
END_FUNCTION_BLOCK
