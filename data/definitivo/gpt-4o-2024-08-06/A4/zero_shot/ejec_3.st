```pascal
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;        // Setpoint de velocidad
    paroRapido : BOOL;   // Indicador de paro rápido
    ciclo : TIME;        // Período de ejecución del bloque
END_VAR
VAR_OUTPUT
    CVvel : REAL;        // Velocidad de consigna generada
END_VAR
VAR
    incremento : REAL;   // Incremento calculado para CVvel
    tiempoSegundos : REAL; // Tiempo de ciclo en segundos
END_VAR

// Conversión del tiempo de ciclo de TIME a REAL en segundos
tiempoSegundos := REAL_TO_TIME(ciclo) / 1000.0;

// Comportamiento en caso de paro rápido
IF paroRapido THEN
    incremento := -40.0 * tiempoSegundos; // Descenso rápido
    CVvel := CVvel + incremento;
    IF CVvel < 0.0 THEN
        CVvel := 0.0; // Asegurar que no baje de 0.0
    END_IF
ELSE
    // Comportamiento normal
    IF SPvel > CVvel THEN
        incremento := 10.0 * tiempoSegundos; // Subida controlada
        CVvel := CVvel + incremento;
        IF CVvel > SPvel THEN
            CVvel := SPvel; // Evitar sobrepaso
        END_IF
    ELSIF SPvel < CVvel THEN
        incremento := -20.0 * tiempoSegundos; // Bajada controlada
        CVvel := CVvel + incremento;
        IF CVvel < SPvel THEN
            CVvel := SPvel; // Evitar sobrepaso
        END_IF
    END_IF
END_IF

END_FUNCTION_BLOCK
```

Este código implementa un generador de consigna de velocidad con rampa en un bloque de función llamado `FB_Rampa`, siguiendo el estándar IEC 61131-3. La salida `CVvel` sigue la consigna `SPvel` con pendientes controladas y considera un modo de paro rápido.