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
    tEstrella : TON;
    (* Temporizador tiempo muerto: 100 ms entre kY y kD *)
    tMuerto   : TON;

    (* Máquina de estados *)
    eEstado   : INT; (* 0=Reposo 1=Estrella 2=TiempoMuerto 3=Triangulo *)
END_VAR

(* ─────────────────────────────────────────────
   Máquina de estados estrella-triángulo
   ───────────────────────────────────────────── *)

CASE eEstado OF

    (* ── ESTADO 0: Reposo ── *)
    0:
        kM := FALSE;
        kY := FALSE;
        kD := FALSE;

        IF btnMarcha AND NOT btnParo THEN
            eEstado := 1; (* Pasar a estrella *)
        END_IF;

    (* ── ESTADO 1: Marcha en estrella ── *)
    1:
        kM := TRUE;
        kY := TRUE;  (* Estrella activa  *)
        kD := FALSE; (* Triángulo inactivo — interbloqueo *)

        (* Arrancar temporizador de 8 s *)
        tEstrella(IN := TRUE, PT := T#8S);

        IF btnParo THEN
            (* Paro de emergencia *)
            tEstrella(IN := FALSE, PT := T#8S);
            eEstado := 0;
        ELSIF tEstrella.Q THEN
            (* Fin de tiempo en estrella *)
            tEstrella(IN := FALSE, PT := T#8S);
            kY := FALSE; (* Desactivar estrella antes de tiempo muerto *)
            eEstado := 2;
        END_IF;

    (* ── ESTADO 2: Tiempo muerto (kY y kD ambos OFF) ── *)
    2:
        kM := TRUE;
        kY := FALSE; (* Interbloqueo: estrella ya apagada  *)
        kD := FALSE; (* Interbloqueo: triángulo aún apagado *)

        (* Arrancar temporizador de 100 ms *)
        tMuerto(IN := TRUE, PT := T#100MS);

        IF btnParo THEN
            tMuerto(IN := FALSE, PT := T#100MS);
            eEstado := 0;
        ELSIF tMuerto.Q THEN
            tMuerto(IN := FALSE, PT := T#100MS);
            eEstado := 3;
        END_IF;

    (* ── ESTADO 3: Marcha en triángulo ── *)
    3:
        kM := TRUE;
        kY := FALSE; (* Interbloqueo: estrella siempre OFF *)
        kD := TRUE;  (* Triángulo activo                  *)

        IF btnParo THEN
            eEstado := 0;
        END_IF;

    (* ── Estado desconocido: ir a reposo ── *)
    ELSE
        eEstado := 0;

END_CASE;

END_FUNCTION_BLOCK