FUNCTION_BLOCK FB_Batch

VAR_INPUT
    nivelA    : BOOL;   (* Sensor nivel componente A alcanzado *)
    nivelB    : BOOL;   (* Sensor nivel componente B alcanzado *)
    nivelVacio : BOOL;  (* Sensor reactor vacío *)
    btnInicio : BOOL;   (* Botón inicio receta (flanco no requerido, nivel) *)
    btnAbort  : BOOL;   (* Botón abort *)
    temp      : REAL;   (* Temperatura actual del reactor *)
END_VAR

VAR_OUTPUT
    vA        : BOOL;   (* Válvula componente A *)
    vB        : BOOL;   (* Válvula componente B *)
    calentador : BOOL;  (* Calentador *)
    mezclador : BOOL;   (* Mezclador *)
    vDescarga : BOOL;   (* Válvula de descarga *)
    fase      : INT;    (* Fase activa: 0=reposo, 1-5=fases receta *)
END_VAR

VAR
    timerMezcla   : TON;        (* Temporizador fase 4 mezcla *)
    abortActivo   : BOOL;       (* Indica que se está ejecutando un abort *)
    btnInicioAnterior : BOOL;   (* Flanco ascendente btnInicio *)
    btnAbortAnterior  : BOOL;   (* Flanco ascendente btnAbort *)
    flancoInicio  : BOOL;       (* Flanco detectado btnInicio *)
    flancoAbort   : BOOL;       (* Flanco detectado btnAbort *)
END_VAR

(* ─── Detección de flancos ascendentes ─────────────────────────────────── *)
flancoInicio := btnInicio AND NOT btnInicioAnterior;
flancoAbort  := btnAbort  AND NOT btnAbortAnterior;

(* ─── Lógica principal por fase ─────────────────────────────────────────── *)

(* --- Gestión de ABORT (fases 1 a 5) ------------------------------------ *)
IF flancoAbort AND (fase >= 1) AND (fase <= 5) THEN
    abortActivo := TRUE;

    (* Apagar actuadores de proceso inmediatamente *)
    vA         := FALSE;
    vB         := FALSE;
    calentador := FALSE;
    mezclador  := FALSE;

    (* Decidir siguiente estado *)
    IF fase = 5 THEN
        (* Ya estamos descargando: continuar fase 5 sin cambio *)
        (* abortActivo queda TRUE para que al vaciar vuelva a reposo *)
        (* No se cambia fase *)
    ELSIF nivelVacio THEN
        (* Reactor ya vacío: ir directamente a reposo *)
        vDescarga  := FALSE;
        fase       := 0;
        abortActivo := FALSE;
    ELSE
        (* Hay producto: ir a fase 5 para descargar *)
        fase := 5;
    END_IF;
END_IF;

(* --- Máquina de estados ------------------------------------------------- *)
CASE fase OF

    (* ── FASE 0: Reposo ─────────────────────────────────────────────── *)
    0:
        (* Asegurar todas las salidas apagadas *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        abortActivo := FALSE;

        (* Arranque solo con flanco de btnInicio *)
        IF flancoInicio THEN
            fase := 1;
        END_IF;

    (* ── FASE 1: Dosificar componente A ─────────────────────────────── *)
    1:
        vA := TRUE;

        IF nivelA THEN
            vA   := FALSE;
            fase := 2;
        END_IF;

    (* ── FASE 2: Dosificar componente B ─────────────────────────────── *)
    2:
        vB := TRUE;

        IF nivelB THEN
            vB   := FALSE;
            fase := 3;
        END_IF;

    (* ── FASE 3: Calentar hasta 60 °C ───────────────────────────────── *)
    3:
        calentador := TRUE;

        IF temp >= 60.0 THEN
            calentador := FALSE;
            fase       := 4;
            (* Reiniciar temporizador antes de entrar en fase 4 *)
            timerMezcla(IN := FALSE, PT := T#120S);
        END_IF;

    (* ── FASE 4: Mezclar 120 segundos ───────────────────────────────── *)
    4:
        mezclador := TRUE;
        timerMezcla(IN := TRUE, PT := T#120S);

        IF timerMezcla.Q THEN
            mezclador := FALSE;
            timerMezcla(IN := FALSE, PT := T#120S); (* Reset timer *)
            fase := 5;
        END_IF;

    (* ── FASE 5: Descargar hasta reactor vacío ──────────────────────── *)
    5:
        vDescarga := TRUE;

        IF nivelVacio THEN
            vDescarga   := FALSE;
            fase        := 0;
            abortActivo := FALSE;
        END_IF;

    (* ── Estado no definido: volver a reposo ────────────────────────── *)
    ELSE:
        fase := 0;

END_CASE;

(* ─── Actualizar memoria de flancos ─────────────────────────────────────── *)
btnInicioAnterior := btnInicio;
btnAbortAnterior  := btnAbort;