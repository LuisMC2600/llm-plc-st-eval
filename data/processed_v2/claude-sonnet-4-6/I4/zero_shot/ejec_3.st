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

(* ─────────────────────────────────────────────────────────────
   Máquina de estados para arranque estrella-triángulo
   Estado 0 : Reposo       – todo apagado
   Estado 1 : Estrella     – kM + kY activos, temporizando 8 s
   Estado 2 : Tiempo muerto– kM activo, kY y kD apagados, 100 ms
   Estado 3 : Triángulo    – kM + kD activos
   ───────────────────────────────────────────────────────────── *)

(* Paro inmediato desde cualquier estado *)
IF btnParo THEN
    eEstado := 0;
END_IF;

CASE eEstado OF

    (* ── Estado 0: Reposo ── *)
    0:
        kM := FALSE;
        kY := FALSE;
        kD := FALSE;
        tEstrella(IN := FALSE, PT := T#8S);   (* Resetear temporizadores *)
        tMuerto  (IN := FALSE, PT := T#100MS);

        IF btnMarcha THEN
            eEstado := 1; (* Pasar a estrella *)
        END_IF;

    (* ── Estado 1: Funcionamiento en estrella ── *)
    1:
        kM := TRUE;
        kY := TRUE;  (* Estrella activa  *)
        kD := FALSE; (* Triángulo inactivo – interbloqueo explícito *)

        tEstrella(IN := TRUE, PT := T#8S);

        IF tEstrella.Q THEN
            (* Tiempo en estrella cumplido: apagar kY y arrancar tiempo muerto *)
            kY      := FALSE;
            tEstrella(IN := FALSE, PT := T#8S); (* Reset del temporizador *)
            eEstado := 2;
        END_IF;

    (* ── Estado 2: Tiempo muerto (kY y kD ambos apagados) ── *)
    2:
        kM := TRUE;
        kY := FALSE; (* Interbloqueo: estrella apagada  *)
        kD := FALSE; (* Interbloqueo: triángulo apagado *)

        tMuerto(IN := TRUE, PT := T#100MS);

        IF tMuerto.Q THEN
            tMuerto(IN := FALSE, PT := T#100MS); (* Reset del temporizador *)
            eEstado := 3;
        END_IF;

    (* ── Estado 3: Funcionamiento en triángulo ── *)
    3:
        kM := TRUE;
        kY := FALSE; (* Estrella inactiva – interbloqueo explícito *)
        kD := TRUE;  (* Triángulo activo  *)

    (* ── Estado por defecto: volver a reposo ── *)
    ELSE
        eEstado := 0;

END_CASE;