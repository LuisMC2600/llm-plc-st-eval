FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL; (* Boton de marcha en sentido horario *)
    btnRev : BOOL; (* Boton de marcha en sentido antihorario *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida para giro horario *)
    rev : BOOL; (* Salida para giro antihorario *)
END_VAR

(* Enclavamiento para giro horario: requiere que no este activo el paro ni el giro opuesto *)
fwd := (fwd OR btnFwd) AND NOT btnParo AND NOT rev;

(* Enclavamiento para giro antihorario: requiere que no este activo el paro ni el giro opuesto *)
rev := (rev OR btnRev) AND NOT btnParo AND NOT fwd;
END_FUNCTION_BLOCK