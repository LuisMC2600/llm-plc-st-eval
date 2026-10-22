FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL;       // Sensor de nivel para el componente A
    nivelB : BOOL;       // Sensor de nivel para el componente B
    nivelVacio : BOOL;   // Sensor de nivel para el estado vacío
    btnInicio : BOOL;    // Botón de inicio
    btnAbort : BOOL;     // Botón de aborto
    temp : REAL;         // Temperatura actual del reactor
END_VAR

VAR_OUTPUT
    vA : BOOL;           // Válvula para el componente A
    vB : BOOL;           // Válvula para el componente B
    calentador : BOOL;   // Calentador del reactor
    mezclador : BOOL;    // Mezclador del reactor
    vDescarga : BOOL;    // Válvula de descarga
    fase : INT;          // Fase actual del proceso
END_VAR

VAR
    timerMezcla : TON;   // Temporizador para la fase de mezcla
    mezclaTiempo : TIME := T#120S; // Tiempo de mezcla
    recetaEnCurso : BOOL; // Indica si la receta está en curso
END_VAR

// Inicialización
IF NOT recetaEnCurso THEN
    fase := 0;
END_IF

// Control de la receta
CASE fase OF
    0: // Reposo
        vA := FALSE;
        vB := FALSE;
        calentador := FALSE;
        mezclador := FALSE;
        vDescarga := FALSE;
        IF btnInicio AND NOT recetaEnCurso THEN
            recetaEnCurso := TRUE;
            fase := 1;
        END_IF

    1: // Fase 1: Dosificación de A
        vA := TRUE;
        IF nivelA THEN
            vA := FALSE;
            fase := 2;
        END_IF

    2: // Fase 2: Dosificación de B
        vB := TRUE;
        IF nivelB THEN
            vB := FALSE;
            fase := 3;
        END_IF

    3: // Fase 3: Calentamiento
        calentador := TRUE;
        IF temp >= 60.0 THEN
            calentador := FALSE;
            fase := 4;
        END_IF

    4: // Fase 4: Mezcla
        mezclador := TRUE;
        timerMezcla(IN := TRUE, PT := mezclaTiempo);
        IF timerMezcla.Q THEN
            mezclador := FALSE;
            fase := 5;
        END_IF

    5: // Fase 5: Descarga
        vDescarga := TRUE;
        IF nivelVacio THEN
            vDescarga := FALSE;
            recetaEnCurso := FALSE;
            fase := 0;
        END_IF
END_CASE

// Manejo del botón de aborto
IF btnAbort AND recetaEnCurso THEN
    vA := FALSE;
    vB := FALSE;
    calentador := FALSE;
    mezclador := FALSE;
    IF NOT nivelVacio THEN
        fase := 5; // Forzar descarga si no está vacío
    ELSE
        recetaEnCurso := FALSE;
        fase := 0; // Volver a reposo si ya está vacío
    END_IF
END_IF

END_FUNCTION_BLOCK