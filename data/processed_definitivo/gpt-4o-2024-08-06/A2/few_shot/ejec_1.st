FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL; (* Sensor de nivel para componente A *)
    nivelB : BOOL; (* Sensor de nivel para componente B *)
    nivelVacio : BOOL; (* Sensor de nivel para tanque vacío *)
    btnInicio : BOOL; (* Botón de inicio de receta *)
    btnAbort : BOOL; (* Botón de aborto de receta *)
    temp : REAL; (* Temperatura actual del reactor *)
END_VAR
VAR_OUTPUT
    vA : BOOL; (* Válvula para componente A *)
    vB : BOOL; (* Válvula para componente B *)
    calentador : BOOL; (* Calentador del reactor *)
    mezclador : BOOL; (* Mezclador del reactor *)
    vDescarga : BOOL; (* Válvula de descarga *)
    fase : INT; (* Fase actual del proceso *)
END_VAR
VAR
    tMezcla : TON; (* Temporizador para la fase de mezcla *)
    recetaEnCurso : BOOL; (* Indica si la receta está en curso *)
END_VAR

(* Inicialización de salidas y variables *)
vA := FALSE;
vB := FALSE;
calentador := FALSE;
mezclador := FALSE;
vDescarga := FALSE;

(* Control de fases del proceso por lotes *)
CASE fase OF
    0: (* Reposo *)
        IF btnInicio AND NOT recetaEnCurso THEN
            fase := 1; (* Iniciar receta desde reposo *)
            recetaEnCurso := TRUE;
        END_IF

    1: (* Fase 1: Dosificación de A *)
        vA := NOT nivelA;
        IF nivelA THEN
            vA := FALSE;
            fase := 2;
        END_IF

    2: (* Fase 2: Dosificación de B *)
        vB := NOT nivelB;
        IF nivelB THEN
            vB := FALSE;
            fase := 3;
        END_IF

    3: (* Fase 3: Calentamiento *)
        calentador := temp < 60.0;
        IF temp >= 60.0 THEN
            calentador := FALSE;
            fase := 4;
        END_IF

    4: (* Fase 4: Mezcla *)
        mezclador := TRUE;
        tMezcla(IN := TRUE, PT := T#120S);
        IF tMezcla.Q THEN
            mezclador := FALSE;
            fase := 5;
        END_IF

    5: (* Fase 5: Descarga *)
        vDescarga := NOT nivelVacio;
        IF nivelVacio THEN
            vDescarga := FALSE;
            fase := 0;
            recetaEnCurso := FALSE;
        END_IF
END_CASE

(* Manejo del botón de aborto *)
IF btnAbort THEN
    vA := FALSE;
    vB := FALSE;
    calentador := FALSE;
    mezclador := FALSE;
    IF fase <> 0 THEN
        IF NOT nivelVacio THEN
            fase := 5; (* Ir a descarga si no está vacío *)
        ELSE
            fase := 0; (* Ir a reposo si ya está vacío *)
            recetaEnCurso := FALSE;
        END_IF
    END_IF
END_IF

END_FUNCTION_BLOCK