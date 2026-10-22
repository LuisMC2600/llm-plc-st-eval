FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL;      // Sensor de nivel para componente A
    nivelB : BOOL;      // Sensor de nivel para componente B
    nivelVacio : BOOL;  // Sensor de nivel para tanque vacío
    btnInicio : BOOL;   // Botón de inicio de la receta
    btnAbort : BOOL;    // Botón de aborto de la receta
    temp : REAL;        // Temperatura actual del reactor
END_VAR

VAR_OUTPUT
    vA : BOOL;          // Válvula para dosificar componente A
    vB : BOOL;          // Válvula para dosificar componente B
    calentador : BOOL;  // Calentador del reactor
    mezclador : BOOL;   // Mezclador del reactor
    vDescarga : BOOL;   // Válvula de descarga del reactor
    fase : INT;         // Fase actual del proceso
END_VAR

VAR
    timerMezcla : TON;  // Temporizador para la fase de mezcla
    recetaEnCurso : BOOL; // Indica si la receta está en curso
END_VAR

// Inicialización de variables
IF NOT recetaEnCurso THEN
    fase := 0;
END_IF

// Lógica de control por lotes
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
        timerMezcla(IN := TRUE, PT := T#120S);
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

// Lógica de aborto
IF btnAbort AND recetaEnCurso THEN
    vA := FALSE;
    vB := FALSE;
    calentador := FALSE;
    mezclador := FALSE;
    
    IF NOT nivelVacio THEN
        fase := 5; // Ir a descarga si no está vacío
    ELSE
        recetaEnCurso := FALSE;
        fase := 0; // Ir a reposo si ya está vacío
    END_IF
END_IF

END_FUNCTION_BLOCK