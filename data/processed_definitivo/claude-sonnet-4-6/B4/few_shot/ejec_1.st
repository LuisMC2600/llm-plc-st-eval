FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; (* Boton marcha sentido horario *)
    btnRev  : BOOL; (* Boton marcha sentido antihorario *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida sentido horario *)
    rev : BOOL; (* Salida sentido antihorario *)
END_VAR
VAR
    stateFwd : BOOL; (* Estado interno: motor girando en horario *)
    stateRev : BOOL; (* Estado interno: motor girando en antihorario *)
END_VAR

(* Paro: desactiva ambos sentidos *)
IF btnParo THEN
    stateFwd := FALSE;
    stateRev := FALSE;

(* Arranque horario: solo si el sentido antihorario esta detenido *)
ELSIF btnFwd AND NOT stateRev THEN
    stateFwd := TRUE;

(* Arranque antihorario: solo si el sentido horario esta detenido *)
ELSIF btnRev AND NOT stateFwd THEN
    stateRev := TRUE;
END_IF;

(* Asignacion de salidas; garantia hardware: nunca ambas activas *)
fwd := stateFwd AND NOT stateRev;
rev := stateRev AND NOT stateFwd;

END_FUNCTION_BLOCK