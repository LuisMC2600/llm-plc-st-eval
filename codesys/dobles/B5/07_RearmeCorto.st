(* DOBLE DE PRUEBA B5/RearmeCorto - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 7 *)
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL;
END_VAR
VAR_OUTPUT
    ventilador : BOOL;
END_VAR
VAR
    tAhora : TIME;
    tPrev : TIME;
    dScan : TIME;
    init : BOOL;
    acum : TIME;
    ciclos : INT;
    prev : BOOL;
    pt : TIME;
END_VAR
tAhora := TIME();
IF NOT init THEN
    tPrev := tAhora;
    init := TRUE;
END_IF
dScan := tAhora - tPrev;
tPrev := tAhora;
IF quemadorOn THEN
    ventilador := TRUE;
    acum := T#0S;
ELSE
    IF prev THEN
        ciclos := ciclos + 1;    (* flanco de bajada del quemador *)
    END_IF
    acum := acum + dScan;
    IF ciclos <= 1 THEN
        pt := T#30S;
    ELSE
        pt := T#15S;
    END_IF
    IF acum >= pt THEN
        ventilador := FALSE;
    END_IF
END_IF
prev := quemadorOn;
END_FUNCTION_BLOCK
