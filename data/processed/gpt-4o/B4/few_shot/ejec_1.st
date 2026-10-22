FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL; (* Botón para giro horario *)
    btnRev : BOOL; (* Botón para giro antihorario *)
    btnParo : BOOL; (* Botón de paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida para giro horario *)
    rev : BOOL; (* Salida para giro antihorario *)
END_VAR
VAR
    estado : INT; (* Estado actual del motor: 0 = Paro, 1 = Horario, 2 = Antihorario *)
END_VAR

(* Lógica de control de inversión de giro del motor *)
IF btnParo THEN
    estado := 0; (* Motor en estado de paro *)
ELSIF btnFwd AND (estado = 0) THEN
    estado := 1; (* Motor en estado de giro horario *)
ELSIF btnRev AND (estado = 0) THEN
    estado := 2; (* Motor en estado de giro antihorario *)
END_IF

(* Asignación de salidas según el estado *)
fwd := (estado = 1);
rev := (estado = 2);
END_FUNCTION_BLOCK