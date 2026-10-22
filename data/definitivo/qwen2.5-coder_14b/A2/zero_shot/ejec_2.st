```pascal
FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA, nivelB, nivelVacio, btnInicio, btnAbort : BOOL;
    temp : REAL;
END_VAR

VAR_OUTPUT
    vA, vB, calentador, mezclador, vDescarga : BOOL;
    fase : INT;
END_VAR

VAR
    timerMezclador : TON;
    estado : INT := 0; // 0: reposo, 1: dosificar A, 2: dosificar B, 3: calentar, 4: mezclar, 5: descargar
    timerMezcladorActive : BOOL := FALSE;
END_VAR

METHOD StartBatch : BOOL
    IF btnInicio AND estado = 0 THEN
        estado := 1;
        RETURN TRUE;
    END_IF
    RETURN FALSE;
END_METHOD

METHOD AbortBatch : BOOL
    IF btnAbort AND estado > 0 THEN
        vA := FALSE;
        vB := FALSE;
        calentador := FALSE;
        mezclador := FALSE;
        IF NOT nivelVacio THEN
            estado := 5;
        ELSE
            estado := 0;
        END_IF
        RETURN TRUE;
    END_IF
    RETURN FALSE;
END_METHOD

METHOD UpdateBatch : BOOL
    CASE estado OF
        0: // Reposo
            vA := FALSE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := FALSE;
            vDescarga := FALSE;
            fase := 0;
        1: // Dosificar A
            vA := TRUE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := FALSE;
            vDescarga := FALSE;
            fase := 1;
            IF nivelA THEN
                vA := FALSE;
                estado := 2;
            END_IF;
        2: // Dosificar B
            vA := FALSE;
            vB := TRUE;
            calentador := FALSE;
            mezclador := FALSE;
            vDescarga := FALSE;
            fase := 2;
            IF nivelB THEN
                vB := FALSE;
                estado := 3;
            END_IF;
        3: // Calentar
            vA := FALSE;
            vB := FALSE;
            calentador := TRUE;
            mezclador := FALSE;
            vDescarga := FALSE;
            fase := 3;
            IF temp >= 60.0 THEN
                calentador := FALSE;
                estado := 4;
            END_IF;
        4: // Mezclar
            vA := FALSE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := TRUE;
            vDescarga := FALSE;
            fase := 4;
            IF NOT timerMezcladorActive THEN
                timerMezclador(IN := TRUE, PT := T#120S);
                timerMezcladorActive := TRUE;
            END_IF;
            IF timerMezclador.Q THEN
                mezclador := FALSE;
                timerMezcladorActive := FALSE;
                estado := 5;
            END_IF;
        5: // Descargar
            vA := FALSE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := FALSE;
            vDescarga := TRUE;
            fase := 5;
            IF nivelVacio THEN
                vDescarga := FALSE;
                estado := 0;
            END_IF;
    END_CASE
    RETURN TRUE;
END_METHOD

METHOD Execute : BOOL
    IF AbortBatch() THEN
        RETURN TRUE;
    END_IF;
    IF StartBatch() THEN
        RETURN TRUE;
    END_IF;
    IF UpdateBatch() THEN
        RETURN TRUE;
    END_IF;
    RETURN FALSE;
END_METHOD

METHOD Reset : BOOL
    estado := 0;
    RETURN TRUE;
END_METHOD
END_FUNCTION_BLOCK
```