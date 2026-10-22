```pascal
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo   : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor estrella *)
    kD : BOOL; (* Contactor triangulo *)
END_VAR
VAR
    marcha    : BOOL; (* Memoria de marcha (enclavamiento) *)
    tEstrella : TON;  (* Temporizador fase estrella: 8 s *)
    tMuerto   : TON;  (* Temporizador tiempo muerto: 100 ms *)
END_VAR

(* --- Gestion del enclavamiento de marcha/paro --- *)
IF btnParo THEN
    marcha := FALSE;
ELSIF btnMarcha THEN
    marcha := TRUE;
END_IF;

(* --- Temporizador de fase estrella (8 s desde el arranque) --- *)
tEstrella(IN := marcha, PT := T#8S);

(* --- Temporizador de tiempo muerto (100 ms tras fin de estrella) --- *)
tMuerto(IN := tEstrella.Q, PT := T#100MS);

(* --- Asignacion de salidas --- *)
(* Contactor principal: activo mientras haya marcha *)
kM := marcha;

(* Contactor estrella: activo desde el arranque hasta que vence tEstrella *)
kY := marcha AND NOT tEstrella.Q;

(* Contactor triangulo: activo solo tras el tiempo muerto; nunca simultaneo con kY *)
kD := marcha AND tMuerto.Q AND NOT kY;

END_FUNCTION_BLOCK
```