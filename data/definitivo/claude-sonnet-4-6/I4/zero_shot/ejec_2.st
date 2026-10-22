```pascal
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; (* Pulsador de marcha *)
    btnParo   : BOOL; (* Pulsador de paro   *)
END_VAR

VAR_OUTPUT
    kM : BOOL; (* Contactor principal  *)
    kY : BOOL; (* Contactor estrella   *)
    kD : BOOL; (* Contactor triángulo  *)
END_VAR

VAR
    (* Temporizador estrella: 8 s en estrella *)
    tEstrella  : TON;
    (* Temporizador tiempo muerto: 100 ms entre kY y kD *)
    tMuerto    : TON;

    (* Máquina de estados *)
    eEstado    : INT; (* 0=Reposo 1=Estrella 2=TiempoMuerto 3=Triangulo *)
END_VAR

(* ─────────────────────────────────────────────
   Lógica principal - Arranque Estrella-Triángulo
   ───────────────────────────────────────────── *)

(* PARO: tiene prioridad absoluta en cualquier estado *)
IF btnParo THEN
    eEstado := 0;
END_IF;

CASE eEstado OF

    (* ── Estado 0: Reposo ── *)
    0:
        kM := FALSE;
        kY := FALSE;
        kD := FALSE;
        tEstrella(IN := FALSE, PT := T#8S);    (* Resetear temporizadores *)
        tMuerto  (IN := FALSE, PT := T#100MS);

        IF btnMarcha AND NOT btnParo THEN
            eEstado := 1; (* Pasar a estrella *)
        END_IF;

    (* ── Estado 1: Funcionamiento en Estrella ── *)
    1:
        kM := TRUE;
        kY := TRUE;  (* Estrella activa  *)
        kD := FALSE; (* Triángulo inactivo - enclavamiento *)

        tEstrella(IN := TRUE, PT := T#8S);
        tMuerto  (IN := FALSE, PT := T#100MS); (* Mantener reseteado *)

        IF tEstrella.Q THEN
            kY      := FALSE;  (* Desactivar estrella antes de cambiar estado *)
            eEstado := 2;      (* Pasar a tiempo muerto *)
        END_IF;

    (* ── Estado 2: Tiempo Muerto (kY y kD ambos inactivos) ── *)
    2:
        kM := TRUE;
        kY := FALSE; (* Estrella inactiva  - enclavamiento garantizado *)
        kD := FALSE; (* Triángulo inactivo - enclavamiento garantizado *)

        tEstrella(IN := TRUE,  PT := T#8S);    (* Mantener Q activo para no resetear *)
        tMuerto  (IN := TRUE,  PT := T#100MS); (* Iniciar cuenta de tiempo muerto *)

        IF tMuerto.Q THEN
            eEstado := 3; (* Pasar a triángulo *)
        END_IF;

    (* ── Estado 3: Funcionamiento en Triángulo ── *)
    3:
        kM := TRUE;
        kY := FALSE; (* Estrella inactiva  - enclavamiento *)
        kD := TRUE;  (* Triángulo activo   *)

        tEstrella(IN := TRUE, PT := T#8S);    (* Mantener temporizadores estables *)
        tMuerto  (IN := TRUE, PT := T#100MS);

        (* Permanece en triángulo hasta que se pulse btnParo *)

    ELSE
        (* Estado desconocido: ir a reposo de forma segura *)
        eEstado := 0;

END_CASE;

(* Enclavamiento hardware por software: garantía adicional *)
(* kY y kD nunca pueden ser TRUE simultáneamente          *)
IF kY AND kD THEN
    kY := FALSE;
    kD := FALSE;
    kM := FALSE;
    eEstado := 0; (* Fallo: volver a reposo *)
END_IF;
```