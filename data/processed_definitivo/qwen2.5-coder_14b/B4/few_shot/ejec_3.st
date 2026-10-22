FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL; (* Boton para girar en sentido horario *)
    btnRev : BOOL; (* Boton para girar en sentido antihorario *)
    btnParo : BOOL; (* Boton para parar el motor *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida para giro horario *)
    rev : BOOL; (* Salida para giro antihorario *)
END_VAR
VAR
    estado : INT := 0; (* Estado actual del motor *)
END_VAR

(* Estados: 0 - Parado, 1 - Giro horario, 2 - Giro antihorario *)
CASE estado OF
    0: (* Parado *)
        IF btnFwd THEN
            estado := 1;
        ELSIF btnRev THEN
            estado := 2;
        END_IF;
    1: (* Giro horario *)
        fwd := TRUE;
        rev := FALSE;
        IF btnParo THEN
            estado := 0;
        ELSIF btnRev THEN
            estado := 2;
        END_IF;
    2: (* Giro antihorario *)
        fwd := FALSE;
        rev := TRUE;
        IF btnParo THEN
            estado := 0;
        ELSIF btnFwd THEN
            estado := 1;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK