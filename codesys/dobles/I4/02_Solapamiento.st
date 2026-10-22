(* DOBLE DE PRUEBA I4/Solapamiento - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 3 *)
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    kM : BOOL;
    kY : BOOL;
    kD : BOOL;
END_VAR
VAR
    estado : INT;
    t1 : TON;
    t2 : TON;
END_VAR
IF btnParo THEN
    kM := FALSE; kY := FALSE; kD := FALSE;
    t1(IN := FALSE, PT := T#8S);
    t2(IN := FALSE, PT := T#100MS);
    estado := 0;
ELSE
    CASE estado OF
        0:
            t1(IN := FALSE, PT := T#8S);
            t2(IN := FALSE, PT := T#100MS);
            IF btnMarcha THEN
                kM := TRUE; kY := TRUE; estado := 1;
            END_IF
        1:
            t1(IN := TRUE, PT := T#8S);
            IF t1.Q THEN kD := TRUE; estado := 2; END_IF
        2:
            t2(IN := TRUE, PT := T#40MS);
            IF t2.Q THEN kY := FALSE; estado := 3; END_IF
    END_CASE
END_IF
END_FUNCTION_BLOCK
