```pascal
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;        // Setpoint de velocidad
    paroRapido : BOOL;   // Indicador de paro rápido
    ciclo : TIME;        // Período de ejecución del bloque
END_VAR

VAR_OUTPUT
    CVvel : REAL;        // Salida de consigna de velocidad
END_VAR

VAR
    incremento : REAL;   // Incremento calculado para CVvel
    tiempoSegundos : REAL; // Tiempo de ciclo en segundos
END_VAR

// Conversión del tiempo de ciclo de TIME a REAL en segundos
tiempoSegundos := REAL_TO_REAL(TIME_TO_REAL(ciclo)) / 1000.0;

// Comportamiento de paro rápido
IF paroRapido THEN
    incremento := -40.0 * tiempoSegundos;
    CVvel := CVvel + incremento;
    IF CVvel < 0.0 THEN
        CVvel := 0.0;
    END_IF
ELSE
    // Comportamiento normal de rampa
    IF SPvel > CVvel THEN
        incremento := 10.0 * tiempoSegundos;
        CVvel := CVvel + incremento;
        IF CVvel > SPvel THEN
            CVvel := SPvel;
        END_IF
    ELSIF SPvel < CVvel THEN
        incremento := -20.0 * tiempoSegundos;
        CVvel := CVvel + incremento;
        IF CVvel < SPvel THEN
            CVvel := SPvel;
        END_IF
    END_IF
END_IF
END_FUNCTION_BLOCK
```

Este código implementa un generador de consigna de velocidad con rampa en un bloque de función llamado `FB_Rampa`. La salida `CVvel` sigue la consigna `SPvel` con pendientes máximas definidas, y responde a un paro rápido reduciendo la velocidad a cero rápidamente.