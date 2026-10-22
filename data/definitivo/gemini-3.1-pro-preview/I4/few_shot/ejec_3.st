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
    tEstrella : TON; (* Temporizador de la fase estrella *)
    tMuerto : TON;   (* Temporizador del tiempo muerto *)
END_VAR

(* Memoria del contactor principal: se activa con marcha, se apaga con paro *)
kM := (btnMarcha OR kM) AND NOT btnParo;

(* Temporizadores para la transicion *)
tEstrella(IN := kM, PT := T#8S);
tMuerto(IN := tEstrella.Q, PT := T#100MS);

(* Contactor estrella: activo al inicio, se apaga a los 8s, interbloqueado con kD *)
kY := kM AND NOT tEstrella.Q AND NOT kD;

(* Contactor triangulo: activo tras el tiempo muerto, interbloqueado con kY *)
kD := kM AND tMuerto.Q AND NOT kY;
END_FUNCTION_BLOCK