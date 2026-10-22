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
    tEstrella : TON; (* Temporizador para el modo estrella *)
    tMuerto : TON;   (* Temporizador para el tiempo muerto *)
    estado : INT;    (* Estado del arranque *)
END_VAR

(* Lógica de control del arranque estrella-triángulo *)
IF btnParo THEN
    (* Si se pulsa el botón de paro, desactivar todos los contactores *)
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSE
    CASE estado OF
        0: (* Estado inicial *)
            IF btnMarcha THEN
                kM := TRUE;  (* Activar contactor principal *)
                kY := TRUE;  (* Activar contactor de estrella *)
                tEstrella(IN := TRUE, PT := T#8S);
                estado := 1;
            END_IF

        1: (* Temporización en modo estrella *)
            IF tEstrella.Q THEN
                kY := FALSE; (* Desactivar contactor de estrella *)
                tMuerto(IN := TRUE, PT := T#100MS);
                estado := 2;
            END_IF

        2: (* Tiempo muerto *)
            IF tMuerto.Q THEN
                kD := TRUE;  (* Activar contactor de triángulo *)
                estado := 3;
            END_IF

        3: (* Modo triángulo *)
            (* Mantener el estado hasta que se pulse el botón de paro *)
            (* No se requiere acción adicional en este estado *)
    END_CASE
END_IF
END_FUNCTION_BLOCK