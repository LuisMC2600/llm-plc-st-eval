(* DOBLE DE PRUEBA B5/SinRearme - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 5 *)
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
END_VAR
tAhora := TIME();
IF NOT init THEN
    tPrev := tAhora;
    init := TRUE;
END_IF
dScan := tAhora - tPrev;
tPrev := tAhora;
IF quemadorOn THEN
    ventilador := TRUE;          (* no reinicia el acumulador *)
ELSE
    acum := acum + dScan;
    IF acum >= T#30S THEN
        ventilador := FALSE;
    END_IF
END_IF
END_FUNCTION_BLOCK
