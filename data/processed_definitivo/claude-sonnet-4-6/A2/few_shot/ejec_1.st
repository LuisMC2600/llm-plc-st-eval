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

(* --- Logica de abort: activo en fases 1 a 5, ignorado en reposo --- *)
IF btnAbort AND (fase >= 1) AND (fase <= 5) THEN
    (* Detener inmediatamente actuadores excepto descarga *)
    vA         := FALSE;
    vB         := FALSE;
    calentador := FALSE;
    mezclador  := FALSE;
    abortando  := TRUE;

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

(* --- Maquina de estados secuencial --- *)
CASE fase OF

    0: (* Reposo *)
        (* Todos los actuadores apagados *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        abortando  := FALSE;
        tMezcla(IN := FALSE, PT := T#120S); (* Resetear temporizador *)

        (* Arranque solo desde reposo *)
        IF btnInicio THEN
            fase := 1;
        END_IF;

    1: (* Dosificar componente A *)
        vA         := TRUE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;

        IF nivelA THEN
            vA   := FALSE;
            fase := 2;
        END_IF;

    2: (* Dosificar componente B *)
        vA         := FALSE;
        vB         := TRUE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;

        IF nivelB THEN
            vB   := FALSE;
            fase := 3;
        END_IF;

    3: (* Calentar hasta 60.0 grados *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := TRUE;
        mezclador  := FALSE;
        vDescarga  := FALSE;

        IF temp >= 60.0 THEN
            calentador := FALSE;
            fase       := 4;
        END_IF;

    4: (* Mezclar durante 120 segundos *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := TRUE;
        vDescarga  := FALSE;

        tMezcla(IN := TRUE, PT := T#120S);

        IF tMezcla.Q THEN
            mezclador := FALSE;
            tMezcla(IN := FALSE, PT := T#120S); (* Resetear para proximo ciclo *)
            fase := 5;
        END_IF;

    5: (* Descargar hasta reactor vacio *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := TRUE;

        IF nivelVacio THEN
            vDescarga := FALSE;
            fase      := 0;
            abortando := FALSE;
        END_IF;

    ELSE
        (* Estado desconocido: volver a reposo de forma segura *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        fase       := 0;
        abortando  := FALSE;

END_CASE;

END_FUNCTION_BLOCK