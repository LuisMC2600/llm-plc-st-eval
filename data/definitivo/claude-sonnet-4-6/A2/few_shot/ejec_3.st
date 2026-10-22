```structured-text
FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA    : BOOL; (* Sensor nivel componente A alcanzado *)
    nivelB    : BOOL; (* Sensor nivel componente B alcanzado *)
    nivelVacio: BOOL; (* Sensor reactor vacio *)
    btnInicio : BOOL; (* Boton arranque receta *)
    btnAbort  : BOOL; (* Boton abortar receta *)
    temp      : REAL; (* Temperatura actual del reactor *)
END_VAR
VAR_OUTPUT
    vA        : BOOL; (* Valvula componente A *)
    vB        : BOOL; (* Valvula componente B *)
    calentador: BOOL; (* Calentador *)
    mezclador : BOOL; (* Mezclador *)
    vDescarga : BOOL; (* Valvula de descarga *)
    fase      : INT;  (* Fase activa: 0=reposo, 1-5=receta *)
END_VAR
VAR
    tMezcla   : TON;  (* Temporizador mezcla 120 s *)
    abortando : BOOL; (* Indica que se esta ejecutando un abort *)
END_VAR

(* ------------------------------------------------------------------ *)
(* Logica de abort: activo en fases 1-5, ignorado en reposo (fase 0)  *)
(* ------------------------------------------------------------------ *)
IF btnAbort AND (fase >= 1) AND (fase <= 5) THEN
    abortando := TRUE;
    (* Cierre inmediato de actuadores excepto vDescarga *)
    vA         := FALSE;
    vB         := FALSE;
    calentador := FALSE;
    mezclador  := FALSE;

    IF fase <> 5 THEN
        (* Si hay producto en el reactor, ir a descarga *)
        IF NOT nivelVacio THEN
            fase := 5;
        ELSE
            (* Reactor ya vacio, volver a reposo *)
            fase      := 0;
            abortando := FALSE;
        END_IF;
    END_IF;
    (* Si ya estabamos en fase 5, continuamos la descarga normalmente *)
END_IF;

(* ------------------------------------------------------------------ *)
(* Maquina de estados de la receta                                     *)
(* ------------------------------------------------------------------ *)
CASE fase OF

    (* ---- FASE 0: Reposo ------------------------------------------ *)
    0:
        (* Asegurar todas las salidas apagadas *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        abortando  := FALSE;

        (* Arranque solo desde reposo y sin abort activo *)
        IF btnInicio THEN
            fase := 1;
        END_IF;

    (* ---- FASE 1: Dosificar componente A --------------------------- *)
    1:
        vA        := TRUE;
        vB        := FALSE;
        calentador:= FALSE;
        mezclador := FALSE;
        vDescarga := FALSE;

        IF nivelA THEN
            vA   := FALSE;
            fase := 2;
        END_IF;

    (* ---- FASE 2: Dosificar componente B --------------------------- *)
    2:
        vA        := FALSE;
        vB        := TRUE;
        calentador:= FALSE;
        mezclador := FALSE;
        vDescarga := FALSE;

        IF nivelB THEN
            vB   := FALSE;
            fase := 3;
        END_IF;

    (* ---- FASE 3: Calentar hasta 60 grados ------------------------- *)
    3:
        vA        := FALSE;
        vB        := FALSE;
        calentador:= TRUE;
        mezclador := FALSE;
        vDescarga := FALSE;

        IF temp >= 60.0 THEN
            calentador := FALSE;
            fase       := 4;
        END_IF;

    (* ---- FASE 4: Mezclar 120 segundos ----------------------------- *)
    4:
        vA        := FALSE;
        vB        := FALSE;
        calentador:= FALSE;
        mezclador := TRUE;
        vDescarga := FALSE;

        (* Temporizador activo mientras estemos en fase 4 *)
        tMezcla(IN := (fase = 4), PT := T#120S);

        IF tMezcla.Q THEN
            mezclador := FALSE;
            fase      := 5;
        END_IF;

    (* ---- FASE 5: Descargar hasta reactor vacio -------------------- *)
    5:
        vA        := FALSE;
        vB        := FALSE;
        calentador:= FALSE;
        mezclador := FALSE;
        vDescarga := TRUE;

        IF nivelVacio THEN
            vDescarga := FALSE;
            fase      := 0; (* Volver a reposo (normal o tras abort) *)
            abortando := FALSE;
        END_IF;

    (* ---- Estado inesperado: volver a reposo seguro ---------------- *)
    ELSE:
        vA        := FALSE;
        vB        := FALSE;
        calentador:= FALSE;
        mezclador := FALSE;
        vDescarga := FALSE;
        abortando := FALSE;
        fase      := 0;

END_CASE;

(* Resetear temporizador cuando no estamos en fase 4 *)
IF fase <> 4 THEN
    tMezcla(IN := FALSE, PT := T#120S);
END_IF;

END_FUNCTION_BLOCK
```