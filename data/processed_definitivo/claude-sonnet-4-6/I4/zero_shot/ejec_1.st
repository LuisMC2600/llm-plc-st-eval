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
    eEstado : INT;
    (*  0 = Reposo
        1 = Marcha en estrella
        2 = Tiempo muerto (kY abierto, kD aún cerrado)
        3 = Marcha en triángulo                        *)
END_VAR

(* ─────────────────────────────────────────────────────────────
   Lógica principal
   ───────────────────────────────────────────────────────────── *)

(* PARO: tiene prioridad absoluta en cualquier estado *)
IF btnParo THEN
    eEstado        := 0;
    tEstrella.IN   := FALSE;
    tMuerto.IN     := FALSE;
END_IF

CASE eEstado OF

    (* ── Estado 0: Reposo ─────────────────────────────────── *)
    0:
        kM := FALSE;
        kY := FALSE;
        kD := FALSE;

        IF btnMarcha AND NOT btnParo THEN
            eEstado := 1; (* Pasar a arranque en estrella *)
        END_IF

    (* ── Estado 1: Marcha en estrella ─────────────────────── *)
    1:
        kM := TRUE;
        kY := TRUE;  (* Estrella activa  *)
        kD := FALSE; (* Triángulo inactivo — nunca simultáneos *)

        (* Arrancar temporizador de 8 s *)
        tEstrella(IN := TRUE, PT := T#8S);

        IF tEstrella.Q THEN
            (* Tiempo en estrella cumplido: abrir kY *)
            tEstrella.IN := FALSE; (* Resetear temporizador *)
            eEstado      := 2;     (* Pasar a tiempo muerto  *)
        END_IF

    (* ── Estado 2: Tiempo muerto (100 ms) ─────────────────── *)
    2:
        kM := TRUE;
        kY := FALSE; (* Estrella ya desactivada  *)
        kD := FALSE; (* Triángulo aún inactivo   *)

        (* Arrancar temporizador de tiempo muerto *)
        tMuerto(IN := TRUE, PT := T#100MS);

        IF tMuerto.Q THEN
            (* Tiempo muerto cumplido: cerrar kD *)
            tMuerto.IN := FALSE; (* Resetear temporizador *)
            eEstado    := 3;     (* Pasar a marcha triángulo *)
        END_IF

    (* ── Estado 3: Marcha en triángulo ────────────────────── *)
    3:
        kM := TRUE;
        kY := FALSE; (* Estrella inactiva — nunca simultáneos *)
        kD := TRUE;  (* Triángulo activo *)

        (* Permanece aquí hasta que se pulse btnParo *)

    ELSE
        (* Estado desconocido: ir a reposo por seguridad *)
        eEstado := 0;

END_CASE

(* ─────────────────────────────────────────────────────────────
   Enclavamiento de seguridad hardware por software:
   garantizar que kY y kD nunca estén activos a la vez.
   ───────────────────────────────────────────────────────────── *)
IF kY AND kD THEN
    kY := FALSE;
    kD := FALSE;
    kM := FALSE;
    eEstado := 0; (* Volver a reposo ante condición anómala *)
END_IF