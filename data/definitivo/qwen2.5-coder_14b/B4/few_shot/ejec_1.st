FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL; (* Boton para girar en sentido horario *)
    btnRev : BOOL; (* Boton para girar en sentido antihorario *)
    btnParo : BOOL; (* Boton para parar *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Sentido horario *)
    rev : BOOL; (* Sentido antihorario *)
END_VAR
VAR
    estado : INT := 0; (* Estado actual del sistema *)
    parado : BOOL := TRUE; (* Indica si el motor está parado *)
END_VAR

(* Estado 0: Parado *)
IF btnParo THEN
    estado := 0;
    parado := TRUE;
    fwd := FALSE;
    rev := FALSE;
ELSIF parado AND btnFwd THEN
    estado := 1;
    parado := FALSE;
    fwd := TRUE;
    rev := FALSE;
ELSIF parado AND btnRev THEN
    estado := 2;
    parado := FALSE;
    fwd := FALSE;
    rev := TRUE;
END_IF

(* Estado 1: Girando en sentido horario *)
IF btnParo THEN
    estado := 0;
    parado := TRUE;
    fwd := FALSE;
    rev := FALSE;
ELSIF btnRev THEN
    estado := 2;
    fwd := FALSE;
    rev := TRUE;
END_IF

(* Estado 2: Girando en sentido antihorario *)
IF btnParo THEN
    estado := 0;
    parado := TRUE;
    fwd := FALSE;
    rev := FALSE;
ELSIF btnFwd THEN
    estado := 1;
    fwd := TRUE;
    rev := FALSE;
END_IF

END_FUNCTION_BLOCK