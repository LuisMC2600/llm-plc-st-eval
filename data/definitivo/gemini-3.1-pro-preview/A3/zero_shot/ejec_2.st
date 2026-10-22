```iecst
FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;
    rxOk : BOOL;
    rxData : INT;
END_VAR
VAR_OUTPUT
    txData : INT;
    ocupado : BOOL;
    ok : BOOL;
    error : BOOL;
    nIntentos : INT;
END_VAR
VAR
    txReq_Trig : R_TRIG;
    rxOk_Trig : R_TRIG;
    temporizador : TON;
    estado : INT := 0; // 0: Reposo, 1: Intercambio en curso
END_VAR

// Detección de flancos ascendentes
txReq_Trig(CLK := txReq);
rxOk_Trig(CLK := rxOk);

// Actualización del temporizador
temporizador(IN := (estado = 1), PT := T#500MS);

CASE estado OF
    0: // Reposo: esperando nueva petición
        IF txReq_Trig.Q THEN
            txData := 100;
            ocupado := TRUE;
            ok := FALSE;
            error := FALSE;
            nIntentos := 1;
            estado := 1;
            
            // Reinicio forzado del temporizador para el intento 1
            temporizador(IN := FALSE);
            temporizador(IN := TRUE, PT := T#500MS);
        END_IF;
        
    1: // Intercambio en curso: esperando respuesta o timeout
        IF rxOk_Trig.Q THEN
            IF rxData = txData THEN
                // Éxito: confirmación recibida con eco correcto
                ok := TRUE;
                ocupado := FALSE;
                estado := 0;
            ELSE
                // Fallo: confirmación recibida pero dato incorrecto
                nIntentos := nIntentos + 1;
                temporizador(IN := FALSE);
                temporizador(IN := TRUE, PT := T#500MS);
            END_IF;
        ELSIF temporizador.Q THEN
            // Fallo: vencimiento del plazo de 500 ms sin confirmación
            nIntentos := nIntentos + 1;
            temporizador(IN := FALSE);
            temporizador(IN := TRUE, PT := T#500MS);
        END_IF;
        
        // Evaluación del límite máximo de intentos
        IF estado = 1 AND nIntentos > 3 THEN
            error := TRUE;
            ocupado := FALSE;
            nIntentos := 3; // Conserva el último valor válido
            estado := 0;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK
```