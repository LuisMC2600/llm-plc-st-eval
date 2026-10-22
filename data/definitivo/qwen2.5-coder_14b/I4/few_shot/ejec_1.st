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
    estado : INT; (* Variable de estado para el arranque estrella-triángulo *)
END_VAR

(* Estado 0: Esperando inicio *)
(* Estado 1: Contacto de estrella activo *)
(* Estado 2: Tiempo muerto *)
(* Estado 3: Contacto de triángulo activo *)

(* Botón de paro desactiva todos los contactores *)
IF btnParo THEN
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0:
            (* Inicia el arranque estrella-triángulo *)
            kM := TRUE;
            kY := TRUE;
            kD := FALSE;
            tEstrella(IN := TRUE, PT := T#8S);
            estado := 1;
        1:
            (* Espera el fin del temporizador de estrella *)
            IF tEstrella.Q THEN
                kY := FALSE;
                tMuerto(IN := TRUE, PT := T#100MS);
                estado := 2;
            END_IF;
        2:
            (* Espera el fin del tiempo muerto *)
            IF tMuerto.Q THEN
                kD := TRUE;
                estado := 3;
            END_IF;
        3:
            (* Mantén el contacto de triángulo activo *)
            kY := FALSE;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK