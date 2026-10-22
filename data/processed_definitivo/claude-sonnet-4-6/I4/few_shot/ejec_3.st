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
    marcha := FALSE; (* Paro inmediato *)
ELSIF btnMarcha THEN
    marcha := TRUE;  (* Arranque *)
END_IF;

(* --- Temporizador de fase estrella (8 s desde el arranque) --- *)
tEstrella(IN := marcha, PT := T#8S);

(* --- Temporizador de tiempo muerto (100 ms tras fin de estrella) --- *)
tMuerto(IN := tEstrella.Q, PT := T#100MS);

(* --- Asignacion de salidas --- *)
kM := marcha;                        (* Contactor principal activo durante toda la marcha *)
kY := marcha AND NOT tEstrella.Q;    (* Estrella: activo hasta que vence el temporizador de 8 s *)
kD := marcha AND tMuerto.Q;          (* Triangulo: activo solo tras el tiempo muerto *)

(* Nota de seguridad: kY y kD no pueden ser TRUE simultaneamente porque
   kY se desactiva cuando tEstrella.Q=TRUE y kD solo se activa cuando
   tMuerto.Q=TRUE (lo que requiere tEstrella.Q=TRUE), garantizando
   al menos 100 ms de separacion entre ambos contactores. *)
END_FUNCTION_BLOCK