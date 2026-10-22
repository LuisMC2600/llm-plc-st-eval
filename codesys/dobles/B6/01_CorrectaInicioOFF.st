(* DOBLE DE PRUEBA B6/CorrectaInicioOFF - NO ES CORPUS. Esperado: veredicto 1 *)
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL;
END_VAR
VAR_OUTPUT
    lampara : BOOL;
END_VAR
VAR
    t1 : TON;
    t2 : TON;
    prevAlarma : BOOL;
END_VAR
IF NOT alarma THEN
    lampara := FALSE;
    t1(IN := FALSE, PT := T#1S);
    t2(IN := FALSE, PT := T#1S);
    prevAlarma := FALSE;
ELSE
    prevAlarma := TRUE;
    IF lampara THEN
        t1(IN := FALSE, PT := T#1S);
        t2(IN := TRUE, PT := T#1S);
        IF t2.Q THEN
            lampara := FALSE;
        END_IF
    ELSE
        t2(IN := FALSE, PT := T#1S);
        t1(IN := TRUE, PT := T#1S);
        IF t1.Q THEN
            lampara := TRUE;
        END_IF
    END_IF
END_IF
END_FUNCTION_BLOCK
