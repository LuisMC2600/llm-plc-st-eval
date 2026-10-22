FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Boton de arranque *)
    btnParo : BOOL;   (* Boton de parada *)
END_VAR
VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor de estrella *)
    kD : BOOL; (* Contactor de triangulo *)
END_VAR
VAR
    enMarcha : BOOL; (* Memoria del estado de marcha *)
    tEstrella : TON; (* Temporizador de la fase estrella *)
    tMuerto : TON;   (* Temporizador del tiempo muerto *)
END_VAR

(* Control de marcha con prioridad a la parada *)
enMarcha := (enMarcha OR btnMarcha) AND NOT btnParo;

(* Temporizadores para la transicion *)
tEstrella(IN := enMarcha, PT := T#8S);
tMuerto(IN := tEstrella.Q, PT := T#100MS);

(* Activacion de contactores con enclavamiento mutuo de seguridad *)
kM := enMarcha;
kY := enMarcha AND NOT tEstrella.Q AND NOT kD;
kD := enMarcha AND tMuerto.Q AND NOT kY;
END_FUNCTION_BLOCK