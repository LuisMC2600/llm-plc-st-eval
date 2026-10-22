```pascal
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha *)
    btnParo : BOOL;   (* Botón de paro *)
END_VAR
VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor de estrella *)
    kD : BOOL; (* Contactor de triángulo *)
END_VAR
VAR
    timerEstrella : TON; (* Temporizador para estrella *)
    timerMuerto : TON;   (* Temporizador para tiempo muerto *)
    estado : INT;        (* Estado del arranque *)
END_VAR

(* Lógica de control del arranque estrella-triángulo *)
IF btnParo THEN
    (* Reset de todos los contactores y temporizadores al pulsar paro *)
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    timerEstrella(IN := FALSE);
    timerMuerto(IN := FALSE);
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0: (* Estado inicial, activa contactor principal y estrella *)
            kM := TRUE;
            kY := TRUE;
            timerEstrella(IN := TRUE, PT := T#8S);
            estado := 1;
        1: (* Espera tiempo de estrella *)
            IF timerEstrella.Q THEN
                kY := FALSE;
                timerMuerto(IN := TRUE, PT := T#100MS);
                estado := 2;
            END_IF
        2: (* Espera tiempo muerto *)
            IF timerMuerto.Q THEN
                kD := TRUE;
                estado := 3;
            END_IF
        3: (* Estado final, contactor de triángulo activado *)
            (* Mantener kM y kD activados *)
    END_CASE
ELSE
    (* Si no se pulsa marcha, reset de todos los contactores y temporizadores *)
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    timerEstrella(IN := FALSE);
    timerMuerto(IN := FALSE);
    estado := 0;
END_IF
END_FUNCTION_BLOCK
```