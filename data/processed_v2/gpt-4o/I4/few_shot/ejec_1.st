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
    tEstrella : TON; (* Temporizador para estrella *)
    tTiempoMuerto : TON; (* Temporizador para tiempo muerto *)
    estado : INT; (* Estado del arranque *)
END_VAR

(* Lógica de control de arranque estrella-triángulo *)
IF btnParo THEN
    (* Reset de todos los contactores y temporizadores en caso de paro *)
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    tEstrella(IN := FALSE);
    tTiempoMuerto(IN := FALSE);
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0: (* Estado inicial, activa contactor principal y estrella *)
            kM := TRUE;
            kY := TRUE;
            tEstrella(IN := TRUE, PT := T#8S);
            estado := 1;
        1: (* Espera el tiempo de estrella *)
            IF tEstrella.Q THEN
                kY := FALSE;
                tTiempoMuerto(IN := TRUE, PT := T#100MS);
                estado := 2;
            END_IF
        2: (* Espera el tiempo muerto *)
            IF tTiempoMuerto.Q THEN
                kD := TRUE;
                estado := 3;
            END_IF
        3: (* Estado final, solo contactor de triángulo activo *)
            (* Mantener kM y kD activos *)
    END_CASE
ELSE
    (* Si no hay marcha ni paro, desactivar todos los contactores *)
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    tEstrella(IN := FALSE);
    tTiempoMuerto(IN := FALSE);
    estado := 0;
END_IF
END_FUNCTION_BLOCK