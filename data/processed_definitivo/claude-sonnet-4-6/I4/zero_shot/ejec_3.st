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
    (* Temporizador para el tiempo en estrella: 8 s *)
    tEstrella  : TON;
    (* Temporizador para el tiempo muerto: 100 ms   *)
    tMuerto    : TON;

    (* Máquina de estados *)
    eEstado : INT := 0;
    (*
        0 = Reposo
        1 = Marcha en estrella
        2 = Tiempo muerto (kY y kD ambos OFF)
        3 = Marcha en triángulo
    *)
END_VAR

(* ─────────────────────────────────────────────────────────────
   Lógica principal: máquina de estados estrella-triángulo
   ───────────────────────────────────────────────────────────── *)

CASE eEstado OF

    (* ── Estado 0: Reposo ─────────────────────────────────── *)
    0:
        kM := FALSE;
        kY := FALSE;
        kD := FALSE;
        tEstrella(IN := FALSE, PT := T#8S);
        tMuerto  (IN := FALSE, PT := T#100MS);

        IF btnMarcha AND NOT btnParo THEN
            eEstado := 1; (* Pasar a arranque en estrella *)
        END_IF;

    (* ── Estado 1: Marcha en estrella ─────────────────────── *)
    1:
        kM := TRUE;
        kY := TRUE;  (* Estrella activa  *)
        kD := FALSE; (* Triángulo inactivo — interbloqueo *)

        (* Arrancar temporizador de estrella *)
        tEstrella(IN := TRUE, PT := T#8S);

        IF btnParo THEN
            eEstado := 0; (* Paro inmediato *)
        ELSIF tEstrella.Q THEN
            (* Tiempo en estrella cumplido → tiempo muerto *)
            tEstrella(IN := FALSE, PT := T#8S); (* Resetear *)
            eEstado := 2;
        END_IF;

    (* ── Estado 2: Tiempo muerto (100 ms) ─────────────────── *)
    2:
        kM := TRUE;
        kY := FALSE; (* Estrella ya desactivada  *)
        kD := FALSE; (* Triángulo aún inactivo   *)

        (* Arrancar temporizador de tiempo muerto *)
        tMuerto(IN := TRUE, PT := T#100MS);

        IF btnParo THEN
            eEstado := 0; (* Paro inmediato *)
        ELSIF tMuerto.Q THEN
            (* Tiempo muerto cumplido → activar triángulo *)
            tMuerto(IN := FALSE, PT := T#100MS); (* Resetear *)
            eEstado := 3;
        END_IF;

    (* ── Estado 3: Marcha en triángulo ────────────────────── *)
    3:
        kM := TRUE;
        kY := FALSE; (* Estrella inactiva — interbloqueo *)
        kD := TRUE;  (* Triángulo activo  *)

        IF btnParo THEN
            eEstado := 0; (* Paro inmediato *)
        END_IF;

    (* ── Estado por defecto: seguridad ───────────────────── *)
    ELSE
        eEstado := 0;

END_CASE;