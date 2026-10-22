```pascal
FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA    : BOOL;   (* Sensor nivel componente A alcanzado *)
    nivelB    : BOOL;   (* Sensor nivel componente B alcanzado *)
    nivelVacio: BOOL;   (* Sensor reactor vacío *)
    btnInicio : BOOL;   (* Botón inicio receta (flanco no requerido, nivel) *)
    btnAbort  : BOOL;   (* Botón abort *)
    temp      : REAL;   (* Temperatura actual del reactor *)
END_VAR

VAR_OUTPUT
    vA        : BOOL;   (* Válvula componente A *)
    vB        : BOOL;   (* Válvula componente B *)
    calentador: BOOL;   (* Calentador *)
    mezclador : BOOL;   (* Mezclador *)
    vDescarga : BOOL;   (* Válvula de descarga *)
    fase      : INT;    (* Fase activa: 0=reposo, 1-5=fases receta *)
END_VAR

VAR
    timerMezcla   : TON;            (* Temporizador fase 4 mezcla *)
    abortando     : BOOL;           (* Indica que se está ejecutando un abort *)
    btnInicio_prev: BOOL;           (* Valor anterior de btnInicio para flanco *)
    btnAbort_prev : BOOL;           (* Valor anterior de btnAbort para flanco *)
    btnInicio_re  : BOOL;           (* Flanco ascendente btnInicio *)
    btnAbort_re   : BOOL;           (* Flanco ascendente btnAbort *)
END_VAR

(* ─────────────────────────────────────────────
   Detección de flancos ascendentes
   ───────────────────────────────────────────── *)
btnInicio_re := btnInicio AND NOT btnInicio_prev;
btnAbort_re  := btnAbort  AND NOT btnAbort_prev;

(* ─────────────────────────────────────────────
   Lógica principal de fases
   ───────────────────────────────────────────── *)
CASE fase OF

    (* ── FASE 0: Reposo ── *)
    0:
        abortando := FALSE;

        (* Arranque solo desde reposo, con flanco de btnInicio *)
        IF btnInicio_re THEN
            fase := 1;
        END_IF;
        (* btnAbort en reposo no tiene efecto *)

    (* ── FASE 1: Dosificar componente A ── *)
    1:
        IF btnAbort_re THEN
            abortando := TRUE;
            (* Cerrar actuadores inmediatamente *)
            vA        := FALSE;
            vB        := FALSE;
            calentador:= FALSE;
            mezclador := FALSE;
            (* Decidir si hay que descargar *)
            IF NOT nivelVacio THEN
                fase := 5;  (* Hay producto: descargar *)
            ELSE
                fase := 0;  (* Reactor ya vacío: reposo *)
            END_IF;
        ELSIF nivelA THEN
            fase := 2;      (* Nivel A alcanzado: siguiente fase *)
        END_IF;

    (* ── FASE 2: Dosificar componente B ── *)
    2:
        IF btnAbort_re THEN
            abortando := TRUE;
            vA        := FALSE;
            vB        := FALSE;
            calentador:= FALSE;
            mezclador := FALSE;
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
        ELSIF nivelB THEN
            fase := 3;      (* Nivel B alcanzado: siguiente fase *)
        END_IF;

    (* ── FASE 3: Calentar ── *)
    3:
        IF btnAbort_re THEN
            abortando := TRUE;
            vA        := FALSE;
            vB        := FALSE;
            calentador:= FALSE;
            mezclador := FALSE;
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
        ELSIF temp >= 60.0 THEN
            fase := 4;      (* Temperatura alcanzada: siguiente fase *)
        END_IF;

    (* ── FASE 4: Mezclar 120 s ── *)
    4:
        IF btnAbort_re THEN
            abortando := TRUE;
            vA        := FALSE;
            vB        := FALSE;
            calentador:= FALSE;
            mezclador := FALSE;
            timerMezcla(IN := FALSE);  (* Resetear temporizador *)
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
        ELSIF timerMezcla.Q THEN
            timerMezcla(IN := FALSE);  (* Resetear temporizador *)
            fase := 5;                 (* Tiempo cumplido: descargar *)
        END_IF;

    (* ── FASE 5: Descargar ── *)
    5:
        (* Un abort durante la descarga continúa la descarga;
           solo se marca abortando si aún no estaba activo *)
        IF btnAbort_re AND NOT abortando THEN
            abortando := TRUE;
            (* Los demás actuadores ya deben estar apagados,
               pero se asegura por si el abort ocurre en fase 5 normal *)
            vA        := FALSE;
            vB        := FALSE;
            calentador:= FALSE;
            mezclador := FALSE;
        END_IF;

        IF nivelVacio THEN
            fase := 0;      (* Reactor vacío: volver a reposo *)
        END_IF;

END_CASE;

(* ─────────────────────────────────────────────
   Asignación de salidas según fase activa
   ───────────────────────────────────────────── *)
CASE fase OF
    0:  (* Reposo: todo apagado *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        timerMezcla(IN := FALSE);

    1:  (* Dosificar A *)
        vA         := TRUE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        timerMezcla(IN := FALSE);

    2:  (* Dosificar B *)
        vA         := FALSE;
        vB         := TRUE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        timerMezcla(IN := FALSE);

    3:  (* Calentar *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := TRUE;
        mezclador  := FALSE;
        vDescarga  := FALSE;
        timerMezcla(IN := FALSE);

    4:  (* Mezclar *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := TRUE;
        vDescarga  := FALSE;
        timerMezcla(IN := TRUE, PT := T#120S);  (* Activar temporizador *)

    5:  (* Descargar *)
        vA         := FALSE;
        vB         := FALSE;
        calentador := FALSE;
        mezclador  := FALSE;
        vDescarga  := TRUE;
        timerMezcla(IN := FALSE);

END_CASE;

(* ─────────────────────────────────────────────
   Actualizar valores previos para próximo ciclo
   ───────────────────────────────────────────── *)
btnInicio_prev := btnInicio;
btnAbort_prev  := btnAbort;
```