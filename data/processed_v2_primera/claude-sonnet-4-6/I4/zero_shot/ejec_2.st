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
    eEstado   : INT; (* 0=Reposo 1=Estrella 2=TiempoMuerto 3=Triángulo *)
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

        (* Arranque: flanco o nivel en btnMarcha, sin paro activo *)
        IF btnMarcha AND NOT btnParo THEN
            eEstado := 1;
        END_IF;

    (* ── ESTADO 1: Marcha en estrella ── *)
    1:
        kM := TRUE;
        kY := TRUE;  (* Estrella activa  *)
        kD := FALSE; (* Triángulo inactivo — interbloqueo *)

        (* Arrancar temporizador de 8 s *)
        tEstrella(IN := TRUE, PT := T#8S);

        IF tEstrella.Q THEN
            (* Fin del tiempo en estrella: desactivar kY *)
            kY      := FALSE;
            tEstrella(IN := FALSE, PT := T#8S); (* Reset temporizador *)
            eEstado := 2;
        END_IF;

    (* ── ESTADO 2: Tiempo muerto (100 ms) ── *)
    2:
        kM := TRUE;
        kY := FALSE; (* Ambos contactores abiertos — interbloqueo garantizado *)
        kD := FALSE;

        (* Arrancar temporizador de tiempo muerto *)
        tMuerto(IN := TRUE, PT := T#100MS);

        IF tMuerto.Q THEN
            tMuerto(IN := FALSE, PT := T#100MS); (* Reset temporizador *)
            eEstado := 3;
        END_IF;

    (* ── ESTADO 3: Marcha en triángulo ── *)
    3:
        kM := TRUE;
        kY := FALSE; (* Estrella inactiva — interbloqueo *)
        kD := TRUE;  (* Triángulo activo  *)

    (* ── Estado desconocido: ir a reposo ── *)
    ELSE
        eEstado := 0;

END_CASE;

(* ─────────────────────────────────────────────
   Paro de emergencia: tiene prioridad absoluta.
   Se evalúa DESPUÉS del CASE para sobreescribir
   cualquier salida activa.
   ───────────────────────────────────────────── *)
IF btnParo THEN
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;

    (* Resetear temporizadores *)
    tEstrella(IN := FALSE, PT := T#8S);
    tMuerto  (IN := FALSE, PT := T#100MS);

    (* Volver a reposo *)
    eEstado := 0;
END_IF;