```iec
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; // Consigna de velocidad deseada
    paroRapido : BOOL; // Indica si se debe activar el paro rápido
    ciclo : TIME; // Período de ejecución del bloque
END_VAR

VAR_OUTPUT
    CVvel : REAL; // Consigna de velocidad actual con rampa
END_VAR

VAR
    lastCVvel : REAL := 0.0; // Valor de CVvel en la última iteración
    rampaSubida : REAL := 10.0; // Pendiente de subida en puntos porcentuales por segundo
    rampaBajada : REAL := 20.0; // Pendiente de bajada en puntos porcentuales por segundo
    rampaParoRapido : REAL := 40.0; // Pendiente de paro rápido en puntos porcentuales por segundo
    tiempoCiclo : TIME := T#0s; // Tiempo transcurrido desde la última iteración
END_VAR

// Calcular el tiempo transcurrido desde la última iteración
tiempoCiclo := ciclo;

// Verificar si se debe activar el paro rápido
IF paroRapido THEN
    // Descender CVvel hacia 0.0 con la pendiente de paro rápido
    CVvel := lastCVvel - rampaParoRapido * REAL(tiempoCiclo / T#1s);
    // Asegurar que CVvel no sea menor que 0.0
    IF CVvel < 0.0 THEN
        CVvel := 0.0;
    END_IF
ELSE
    // Calcular la nueva CVvel con rampa
    IF SPvel > lastCVvel THEN
        // Subida de velocidad
        CVvel := lastCVvel + rampaSubida * REAL(tiempoCiclo / T#1s);
        // Asegurar que CVvel no supere el valor objetivo
        IF CVvel > SPvel THEN
            CVvel := SPvel;
        END_IF
    ELSE
        // Bajada de velocidad
        CVvel := lastCVvel - rampaBajada * REAL(tiempoCiclo / T#1s);
        // Asegurar que CVvel no sea menor que el valor objetivo
        IF CVvel < SPvel THEN
            CVvel := SPvel;
        END_IF
    END_IF
END_IF

// Actualizar el valor de lastCVvel para la próxima iteración
lastCVvel := CVvel;
END_FUNCTION_BLOCK
```