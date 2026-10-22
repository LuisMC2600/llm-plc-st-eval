FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL; (* Boton para giro horario *)
    btnRev : BOOL; (* Boton para giro antihorario *)
    btnParo : BOOL; (* Boton para paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Giro horario *)
    rev : BOOL; (* Giro antihorario *)
END_VAR
VAR
    estado : INT := 0; (* Estado actual del sistema *)
END_VAR

(* Máquina de estados para controlar el giro del motor *)
CASE estado OF
    0: (* Estado de paro *)
        IF btnFwd THEN
            estado := 1; (* Transición a giro horario *)
        ELSIF btnRev THEN
            estado := 2; (* Transición a giro antihorario *)
        END_IF;
    1: (* Estado de giro horario *)
        fwd := TRUE;
        rev := FALSE;
        IF btnParo THEN
            estado := 0; (* Transición a paro *)
        ELSIF btnRev THEN
            estado := 2; (* Transición a giro antihorario *)
        END_IF;
    2: (* Estado de giro antihorario *)
        fwd := FALSE;
        rev := TRUE;
        IF btnParo THEN
            estado := 0; (* Transición a paro *)
        ELSIF btnFwd THEN
            estado := 1; (* Transición a giro horario *)
        END_IF;
END_CASE;
END_FUNCTION_BLOCK