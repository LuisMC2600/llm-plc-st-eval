FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor de estrella *)
    kD : BOOL; (* Contactor de triangulo *)
END_VAR
VAR
    tEstrella : TP; (* Temporizador para el contacto de estrella *)
    tMuerto : TP; (* Temporizador para el tiempo muerto *)
    estado : INT := 0; (* Estado actual del arranque *)
END_VAR

(* Estado 0: Esperando el botón de marcha *)
IF btnMarcha AND estado = 0 THEN
    estado := 1;
    kM := TRUE;
    kY := TRUE;
    kD := FALSE;
    tEstrella(IN := TRUE, PT := T#8S);
ELSIF btnParo THEN
    estado := 0;
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
END_IF

(* Estado 1: Esperando el temporizador de estrella *)
IF estado = 1 AND tEstrella.Q THEN
    estado := 2;
    kY := FALSE;
    tMuerto(IN := TRUE, PT := T#100MS);
END_IF

(* Estado 2: Esperando el tiempo muerto *)
IF estado = 2 AND tMuerto.Q THEN
    estado := 3;
    kD := TRUE;
END_IF

(* Mantener kY y kD inactivos simultáneamente *)
IF kY AND kD THEN
    kY := FALSE;
    kD := FALSE;
END_IF

END_FUNCTION_BLOCK