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
END_VAR

METHOD StartBatch : BOOL
VAR
    started : BOOL := FALSE;
END_VAR
    IF btnInicio AND estado = 0 THEN
        estado := 1;
        started := TRUE;
    END_IF
    StartBatch := started;
END_METHOD

METHOD AbortBatch : BOOL
VAR
    aborted : BOOL := FALSE;
END_VAR
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
        aborted := TRUE;
    END_IF
    AbortBatch := aborted;
END_METHOD

METHOD UpdateBatch : BOOL
VAR
    updated : BOOL := FALSE;
END_VAR
    CASE estado OF
        0: // reposo
            vA := FALSE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := FALSE;
            vDescarga := FALSE;
            fase := 0;
        1: // dosificar A
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
        2: // dosificar B
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
        3: // calentar
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
        4: // mezclar
            vA := FALSE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := TRUE;
            vDescarga := FALSE;
            fase := 4;
            timerMezclador(IN := TRUE, PT := T#120S);
            IF timerMezclador.Q THEN
                mezclador := FALSE;
                estado := 5;
            END_IF;
        5: // descargar
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
    updated := TRUE;
    UpdateBatch := updated;
END_METHOD

METHOD Execute : BOOL
VAR
    executed : BOOL := FALSE;
END_VAR
    IF StartBatch() OR AbortBatch() OR UpdateBatch() THEN
        executed := TRUE;
    END_IF
    Execute := executed;
END_METHOD

// Main execution
Execute();