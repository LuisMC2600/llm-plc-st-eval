```pascal
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha *)
    btnParo : BOOL;   (* Botón de paro *)
END_VAR
VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor estrella *)
    kD : BOOL; (* Contactor triángulo *)
END_VAR
VAR
    tEstrella : TON;  (* Temporizador para estrella *)
    tMuerto : TON;    (* Temporizador para tiempo muerto *)
    estado : INT;     (* Estado del arranque *)
END_VAR

(* Lógica de control del arranque estrella-triángulo *)
IF btnParo THEN
    (* Si se presiona el botón de paro, desactivar todos los contactores *)
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0: (* Estado inicial, activar contactor principal y estrella *)
            kM := TRUE;
            kY := TRUE;
            tEstrella(IN := TRUE, PT := T#8S);
            estado := 1;
        1: (* Esperar 8 segundos con contactor estrella activado *)
            IF tEstrella.Q THEN
                kY := FALSE; (* Desactivar contactor estrella *)
                tMuerto(IN := TRUE, PT := T#100MS);
                estado := 2;
            END_IF
        2: (* Esperar tiempo muerto de 100 ms *)
            IF tMuerto.Q THEN
                kD := TRUE; (* Activar contactor triángulo *)
                estado := 3;
            END_IF
        3: (* Estado final, contactor triángulo activado *)
            (* Mantener estado hasta que se presione btnParo *)
    END_CASE
ELSE
    (* Si no se presiona ningún botón, mantener estado actual *)
    tEstrella(IN := FALSE);
    tMuerto(IN := FALSE);
END_IF
END_FUNCTION_BLOCK
```