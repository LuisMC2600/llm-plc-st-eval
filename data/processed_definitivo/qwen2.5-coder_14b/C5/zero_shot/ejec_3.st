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
    t3 : TON;  // Nuevo temporizador para el tiempo muerto
END_VAR

CASE estado OF
    0:
        IF btnMarcha THEN
            kM := TRUE;
            kY := TRUE;
            estado := 1;
        END_IF
    1:
        t1(IN := TRUE, PT := T#8S);
        IF t1.Q THEN
            kY := FALSE;  // Desactivar kY antes de activar kD
            t3(IN := TRUE, PT := T#100MS);  // Iniciar temporizador para el tiempo muerto
            estado := 2;
        END_IF
    2:
        IF t3.Q THEN  // Esperar el tiempo muerto
            kD := TRUE;
        END_IF
END_CASE

IF btnParo THEN
    kM := FALSE;  // Desactivar kM al pulsar btnParo
    kY := FALSE;
    kD := FALSE;
    estado := 0;
END_IF
END_FUNCTION_BLOCK