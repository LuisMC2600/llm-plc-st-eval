FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha *)
    btnParo : BOOL; (* Botón de paro *)
END_VAR
VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor de estrella *)
    kD : BOOL; (* Contactor de triángulo *)
END_VAR
VAR
    tEstrella : TP; (* Temporizador para el contacto de estrella *)
    tMuerto : TP; (* Temporizador para el tiempo muerto *)
    estado : INT; (* Estado actual del arranque estrella-triángulo *)
END_VAR

(* Estados del arranque estrella-triángulo *)
CONST
    ESTADO_INICIAL := 0;
    ESTADO_ESTRELLA := 1;
    ESTADO_MUERTO := 2;
    ESTADO_TRIANGULO := 3;
END_CONST

(* Paro inmediato *)
IF btnParo THEN
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := ESTADO_INICIAL;
ELSIF btnMarcha THEN
    CASE estado OF
        ESTADO_INICIAL:
            kM := TRUE;
            kY := TRUE;
            kD := FALSE;
            tEstrella(IN := TRUE, PT := T#8S);
            estado := ESTADO_ESTRELLA;
        ESTADO_ESTRELLA:
            IF tEstrella.Q THEN
                kY := FALSE;
                tMuerto(IN := TRUE, PT := T#100MS);
                estado := ESTADO_MUERTO;
            END_IF;
        ESTADO_MUERTO:
            IF tMuerto.Q THEN
                kD := TRUE;
                estado := ESTADO_TRIANGULO;
            END_IF;
        ESTADO_TRIANGULO:
            (* Mantener kD activo mientras kY esté inactivo *)
            kD := TRUE;
    END_CASE;
END_IF;

(* Asegurar que kY y kD no estén activos simultáneamente *)
IF kY AND kD THEN
    kY := FALSE;
END_IF;

END_FUNCTION_BLOCK