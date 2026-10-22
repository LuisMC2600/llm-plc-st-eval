```iecst
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Botón de inicio del motor *)
    btnParo   : BOOL; (* Botón de parada del motor *)
END_VAR

VAR_OUTPUT
    kM : BOOL; (* Contactor principal *)
    kY : BOOL; (* Contactor de estrella *)
    kD : BOOL; (* Contactor de triángulo *)
END_VAR

VAR
    xEnMarcha   : BOOL; (* Memoria de estado del motor *)
    tonEstrella : TON;  (* Temporizador para la fase de estrella *)
    tonTrans    : TON;  (* Temporizador para el tiempo muerto (transición) *)
END_VAR

(* Lógica de retención (Marcha / Paro) *)
IF btnParo THEN
    xEnMarcha := FALSE;
ELSIF btnMarcha THEN
    xEnMarcha := TRUE;
END_IF;

(* Temporizador de la fase Estrella (8 segundos) *)
tonEstrella(IN := xEnMarcha, PT := T#8S);

(* Temporizador de tiempo muerto entre Estrella y Triángulo (100 ms) *)
(* Inicia cuando termina la fase de estrella *)
tonTrans(IN := tonEstrella.Q, PT := T#100MS);

(* Asignación de salidas con enclavamientos de seguridad *)
(* El contactor principal se activa siempre que el sistema esté en marcha *)
kM := xEnMarcha;

(* Estrella: Activo en marcha, antes de los 8s, y NUNCA si Triángulo está activo *)
kY := xEnMarcha AND NOT tonEstrella.Q AND NOT kD;

(* Triángulo: Activo en marcha, tras el tiempo muerto, y NUNCA si Estrella está activo *)
kD := xEnMarcha AND tonTrans.Q AND NOT kY;

END_FUNCTION_BLOCK
```