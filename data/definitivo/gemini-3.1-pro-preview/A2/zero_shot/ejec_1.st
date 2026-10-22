```iecst
FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL;
    nivelB : BOOL;
    nivelVacio : BOOL;
    btnInicio : BOOL;
    btnAbort : BOOL;
    temp : REAL;
END_VAR

VAR_OUTPUT
    vA : BOOL;
    vB : BOOL;
    calentador : BOOL;
    mezclador : BOOL;
    vDescarga : BOOL;
    fase : INT := 0;
END_VAR

VAR
    timerMezcla : TON;
    trigInicio : R_TRIG;
    trigAbort : R_TRIG;
END_VAR

// Detección de flancos para los botones
trigInicio(CLK := btnInicio);
trigAbort(CLK := btnAbort);

// Lógica de Aborto (ignorado en reposo, fase = 0)
IF trigAbort.Q AND fase > 0 THEN
    IF NOT nivelVacio THEN
        fase := 5; // Pasa a descarga si hay producto en el reactor
    ELSE
        fase := 0; // Vuelve a reposo directo si ya está vacío
    END_IF;
END_IF;

// Máquina de estados secuencial
CASE fase OF
    0: // Fase 0: Reposo
        IF trigInicio.Q THEN
            fase := 1;
        END_IF;
        
    1: // Fase 1: Dosificar componente A
        IF nivelA THEN
            fase := 2;
        END_IF;
        
    2: // Fase 2: Dosificar componente B
        IF nivelB THEN
            fase := 3;
        END_IF;
        
    3: // Fase 3: Calentar
        IF temp >= 60.0 THEN
            fase := 4;
        END_IF;
        
    4: // Fase 4: Mezclar
        IF timerMezcla.Q THEN
            fase := 5;
        END_IF;
        
    5: // Fase 5: Descargar
        IF nivelVacio THEN
            fase := 0;
        END_IF;
END_CASE;

// Temporizador de mezcla (se activa únicamente durante la fase 4)
timerMezcla(IN := (fase = 4), PT := T#120S);

// Asignación de salidas (se cierran/apagan automáticamente al cambiar de fase)
vA := (fase = 1);
vB := (fase = 2);
calentador := (fase = 3);
mezclador := (fase = 4);
vDescarga := (fase = 5);

END_FUNCTION_BLOCK
```