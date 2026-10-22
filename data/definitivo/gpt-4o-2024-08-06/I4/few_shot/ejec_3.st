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
    tEstrella : TON; (* Temporizador para el modo estrella *)
    tMuerto : TON;   (* Temporizador para el tiempo muerto *)
    estado : INT;    (* Estado del arranque *)
END_VAR

(* Lógica de control para el arranque estrella-triángulo *)
IF btnParo THEN
    (* Si se presiona el botón de paro, desactivar todos los contactores *)
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0: (* Estado inicial, activar contactor principal y de estrella *)
            kM := TRUE;
            kY := TRUE;
            tEstrella(IN := TRUE, PT := T#8S);
            estado := 1;
        1: (* Esperar 8 segundos en modo estrella *)
            IF tEstrella.Q THEN
                kY := FALSE; (* Desactivar contactor de estrella *)
                tMuerto(IN := TRUE, PT := T#100MS);
                estado := 2;
            END_IF
        2: (* Esperar tiempo muerto de 100 ms *)
            IF tMuerto.Q THEN
                kD := TRUE; (* Activar contactor de triángulo *)
                estado := 3;
            END_IF
        3: (* Modo triángulo activo *)
            (* Mantener el estado hasta que se presione el botón de paro *)
    END_CASE
ELSE
    (* Si no se presiona ningún botón, mantener el estado actual *)
    tEstrella(IN := FALSE);
    tMuerto(IN := FALSE);
END_IF
END_FUNCTION_BLOCK
```