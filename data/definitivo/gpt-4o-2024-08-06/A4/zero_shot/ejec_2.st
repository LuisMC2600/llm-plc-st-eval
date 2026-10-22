```pascal
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;        // Setpoint de velocidad
    paroRapido : BOOL;   // Indicador de paro rápido
    ciclo : TIME;        // Período de ejecución del bloque
END_VAR
VAR_OUTPUT
    CVvel : REAL;        // Salida de velocidad controlada
END_VAR
VAR
    incremento : REAL;   // Incremento calculado para CVvel
    tiempoSegundos : REAL; // Tiempo de ciclo en segundos
END_VAR

// Convertir el tiempo de ciclo de TIME a REAL en segundos
tiempoSegundos := REAL_TO_REAL(TIME_TO_REAL(ciclo)) / 1000.0;

// Comprobar si el paro rápido está activo
IF paroRapido THEN
    // Calcular el decremento para paro rápido
    incremento := -40.0 * tiempoSegundos;
    // Ajustar CVvel asegurando que no sea menor que 0.0
    CVvel := CVvel + incremento;
    IF CVvel < 0.0 THEN
        CVvel := 0.0;
    END_IF
ELSE
    // Calcular la diferencia entre SPvel y CVvel
    incremento := SPvel - CVvel;
    
    // Determinar la dirección del ajuste
    IF incremento > 0.0 THEN
        // Ajuste al alza con pendiente máxima de 10.0
        incremento := 10.0 * tiempoSegundos;
        // Asegurar que CVvel no sobrepase SPvel
        IF CVvel + incremento > SPvel THEN
            CVvel := SPvel;
        ELSE
            CVvel := CVvel + incremento;
        END_IF
    ELSIF incremento < 0.0 THEN
        // Ajuste a la baja con pendiente máxima de 20.0
        incremento := -20.0 * tiempoSegundos;
        // Asegurar que CVvel no caiga por debajo de SPvel
        IF CVvel + incremento < SPvel THEN
            CVvel := SPvel;
        ELSE
            CVvel := CVvel + incremento;
        END_IF
    END_IF
END_IF
END_FUNCTION_BLOCK
```