FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Boton de arranque *)
    btnParo : BOOL; (* Boton de parada *)
END_VAR
VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor de estrella *)
    kD : BOOL; (* Contactor de triangulo *)
END_VAR
VAR
    enMarcha : BOOL; (* Memoria del estado del motor *)
    tEstrella : TON; (* Temporizador para la fase de estrella *)
    tMuerto : TON; (* Temporizador para el tiempo muerto *)
END_VAR

(* Control de marcha con prioridad a la parada *)
enMarcha := (btnMarcha OR enMarcha) AND NOT btnParo;

(* Temporizadores de transicion *)
tEstrella(IN := enMarcha, PT := T#8S);
tMuerto(IN := tEstrella.Q, PT := T#100MS);

(* Asignacion de salidas con enclavamiento de seguridad *)
kM := enMarcha;
kY := enMarcha AND NOT tEstrella.Q AND NOT kD;
kD := enMarcha AND tMuerto.Q AND NOT kY;
END_FUNCTION_BLOCK