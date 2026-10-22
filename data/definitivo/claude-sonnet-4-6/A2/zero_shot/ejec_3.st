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
    fase      : INT;    (* Fase activa: 0=reposo, 1-5=receta *)
END_VAR

VAR
    timerMezcla   : TON;        (* Temporizador fase 4 mezcla *)
    abortando     : BOOL;       (* Indica que se está ejecutando un abort *)
    btnInicioAnterior : BOOL;   (* Para detección de flanco ascendente btnInicio *)
    btnAbortAnterior  : BOOL;   (* Para detección de flanco ascendente btnAbort *)
    flancoInicio  : BOOL;       (* Flanco ascendente btnInicio *)
    flancoAbort   : BOOL;       (* Flanco ascendente btnAbort *)
END_VAR

(* ─────────────────────────────────────────────
   Detección de flancos ascendentes
   ───────────────────────────────────────────── *)
flancoInicio := btnInicio AND NOT btnInicioAnterior;
flancoAbort  := btnAbort  AND NOT btnAbortAnterior;

(* ─────────────────────────────────────────────
   Lógica principal por fases
   ───────────────────────────────────────────── *)
CASE fase OF

    (* ── FASE 0: Reposo ── *)
    0:
        abortando := FALSE;

        (* Arranque solo desde reposo, con flanco *)
        IF flancoInicio THEN
            fase := 1;
        END_IF;
        (* btnAbort en reposo no tiene efecto *)

    (* ── FASE 1: Dosificar componente A ── *)
    1:
        IF flancoAbort THEN
            (* Abort: cerrar actuadores y decidir si descargar *)
            abortando := TRUE;
            IF NOT nivelVacio THEN
                fase := 5;      (* Hay producto → descargar *)
            ELSE
                fase := 0;      (* Reactor ya vacío → reposo *)
            END_IF;
        ELSIF nivelA THEN
            fase := 2;          (* Nivel A alcanzado → siguiente fase *)
        END_IF;

    (* ── FASE 2: Dosificar componente B ── *)
    2:
        IF flancoAbort THEN
            abortando := TRUE;
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
        ELSIF nivelB THEN
            fase := 3;          (* Nivel B alcanzado → siguiente fase *)
        END_IF;

    (* ── FASE 3: Calentar hasta 60 °C ── *)
    3:
        IF flancoAbort THEN
            abortando := TRUE;
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
        ELSIF temp >= 60.0 THEN
            fase := 4;          (* Temperatura alcanzada → siguiente fase *)
        END_IF;

    (* ── FASE 4: Mezclar 120 segundos ── *)
    4:
        IF flancoAbort THEN
            abortando := TRUE;
            timerMezcla(IN := FALSE);   (* Resetear temporizador *)
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
        ELSIF timerMezcla.Q THEN
            timerMezcla(IN := FALSE);   (* Resetear temporizador *)
            fase := 5;                  (* Tiempo cumplido → descargar *)
        END_IF;

    (* ── FASE 5: Descargar ── *)
    5:
        (* Un abort durante fase 5 continúa la descarga normalmente *)
        (* Solo se marca abortando si vino de otra fase; aquí no se interrumpe *)
        IF nivelVacio THEN
            fase := 0;          (* Reactor vacío → reposo *)
            abortando := FALSE;
        END_IF;
        (* flancoAbort en fase 5 se ignora (descarga continúa) *)

END_CASE;

(* ─────────────────────────────────────────────
   Asignación de salidas según fase activa
   ───────────────────────────────────────────── *)

(* Válvula A: abierta solo en fase 1 normal (no en abort) *)
vA := (fase = 1) AND NOT abortando;

(* Válvula B: abierta solo en fase 2 normal *)
vB := (fase = 2) AND NOT abortando;

(* Calentador: activo solo en fase 3 normal *)
calentador := (fase = 3) AND NOT abortando;

(* Mezclador: activo solo en fase 4 normal *)
mezclador := (fase = 4) AND NOT abortando;

(* Válvula descarga: abierta en fase 5 (normal o por abort) *)
vDescarga := (fase = 5);

(* ─────────────────────────────────────────────
   Temporizador mezcla (fase 4)
   ───────────────────────────────────────────── *)
timerMezcla(IN := (fase = 4) AND NOT abortando, PT := T#120S);

(* ─────────────────────────────────────────────
   Actualizar estados anteriores de botones
   ───────────────────────────────────────────── *)
btnInicioAnterior := btnInicio;
btnAbortAnterior  := btnAbort;

END_FUNCTION_BLOCK
```