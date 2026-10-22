FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; // Botón para iniciar giro en sentido horario
    btnRev  : BOOL; // Botón para iniciar giro en sentido antihorario
    btnParo : BOOL; // Botón de paro (TRUE = detener motor)
END_VAR

VAR_OUTPUT
    fwd : BOOL; // Salida para giro en sentido horario
    rev : BOOL; // Salida para giro en sentido antihorario
END_VAR

(* 
   Lógica de giro horario (fwd):
   Se activa con btnFwd o se mantiene enclavada con su propio estado (fwd).
   Condiciones de bloqueo: NO debe estar activo el giro inverso (NOT rev) 
   y NO debe estar presionado el botón de paro (NOT btnParo).
*)
fwd := (btnFwd OR fwd) AND NOT rev AND NOT btnParo;

(* 
   Lógica de giro antihorario (rev):
   Se activa con btnRev o se mantiene enclavada con su propio estado (rev).
   Condiciones de bloqueo: NO debe estar activo el giro horario (NOT fwd) 
   y NO debe estar presionado el botón de paro (NOT btnParo).
*)
rev := (btnRev OR rev) AND NOT fwd AND NOT btnParo;

END_FUNCTION_BLOCK