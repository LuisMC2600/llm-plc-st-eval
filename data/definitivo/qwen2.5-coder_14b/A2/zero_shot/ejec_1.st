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
    estado : INT := 0; // 0: reposo, 1: fase 1, 2: fase 2, 3: fase 3, 4: fase 4, 5: fase 5
END_VAR

METHOD StartBatch : VOID
    IF btnInicio AND estado = 0 THEN
        estado := 1;
    END_IF;
END_METHOD

METHOD AbortBatch : VOID
    IF btnAbort THEN
        vA := FALSE;
        vB := FALSE;
        calentador := FALSE;
        mezclador := FALSE;
        
        IF nivelVacio THEN
            estado := 0;
        ELSE
            estado := 5;
        END_IF;
    END_IF;
END_METHOD

METHOD UpdateBatch : VOID
    CASE estado OF
        0: // Reposo
            fase := 0;
            vA := FALSE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := FALSE;
            vDescarga := FALSE;
            
        1: // Fase 1: Dosificar componente A
            fase := 1;
            vA := TRUE;
            IF nivelA THEN
                vA := FALSE;
                estado := 2;
            END_IF;
            
        2: // Fase 2: Dosificar componente B
            fase := 2;
            vB := TRUE;
            IF nivelB THEN
                vB := FALSE;
                estado := 3;
            END_IF;
            
        3: // Fase 3: Calentar
            fase := 3;
            calentador := TRUE;
            IF temp >= 60.0 THEN
                calentador := FALSE;
                estado := 4;
            END_IF;
            
        4: // Fase 4: Mezclar
            fase := 4;
            mezclador := TRUE;
            timerMezclador(IN := TRUE, PT := T#120S);
            IF timerMezclador.Q THEN
                mezclador := FALSE;
                timerMezclador(IN := FALSE);
                estado := 5;
            END_IF;
            
        5: // Fase 5: Descargar
            fase := 5;
            vDescarga := TRUE;
            IF nivelVacio THEN
                vDescarga := FALSE;
                estado := 0;
            END_IF;
    END_CASE;
END_METHOD

METHOD Execute : VOID
    StartBatch();
    AbortBatch();
    UpdateBatch();
END_METHOD
```

Este código implementa un control por lotes de un reactor siguiendo la receta secuencial proporcionada. El control se maneja a través de un FUNCTION_BLOCK llamado `FB_Batch`, que incluye métodos para iniciar (`StartBatch`), abortar (`AbortBatch`) y actualizar (`UpdateBatch`) el proceso. Las variables de entrada y salida se definen según los requisitos del problema, y el estado del proceso se controla mediante una variable `estado`.