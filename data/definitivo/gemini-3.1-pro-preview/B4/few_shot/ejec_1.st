FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL; (* Boton de giro horario *)
    btnRev : BOOL; (* Boton de giro antihorario *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida de giro horario *)
    rev : BOOL; (* Salida de giro antihorario *)
END_VAR

(* Enclavamiento de giro horario: requiere que no este activo el paro ni el giro inverso *)
fwd := (btnFwd OR fwd) AND NOT btnParo AND NOT rev;

(* Enclavamiento de giro antihorario: requiere que no este activo el paro ni el giro horario *)
rev := (btnRev OR rev) AND NOT btnParo AND NOT fwd;
END_FUNCTION_BLOCK