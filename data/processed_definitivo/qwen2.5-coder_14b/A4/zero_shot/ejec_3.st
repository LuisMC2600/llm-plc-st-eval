FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; // Consigna de velocidad deseada
    paroRapido : BOOL; // Indicador de paro rápido
    ciclo : TIME; // Período de ejecución del bloque
END_VAR

VAR_OUTPUT
    CVvel : REAL; // Consigna de velocidad actualizada con rampa
END_VAR

VAR
    error : REAL; // Diferencia entre SPvel y CVvel
    deltaCVvel : REAL; // Cambio en CVvel durante el ciclo
    maxRampaSubida : REAL := 10.0; // Máxima rampa de subida en puntos porcentuales por segundo
    maxRampaBajada : REAL := 20.0; // Máxima rampa de bajada en puntos porcentuales por segundo
    maxRampaParoRapido : REAL := 40.0; // Máxima rampa de paro rápido en puntos porcentuales por segundo
    cicloSegundos : REAL; // Ciclo convertido a segundos
END_VAR

// Convertir el ciclo de tiempo a segundos
cicloSegundos := REAL(ciclo) / 1000.0;

// Calcular el error entre la consigna deseada y la actual
error := SPvel - CVvel;

// Determinar el cambio en CVvel según las condiciones
IF paroRapido THEN
    // Modo paro rápido: descender hacia 0 con una pendiente máxima
    deltaCVvel := -maxRampaParoRapido * cicloSegundos;
    IF CVvel + deltaCVvel < 0.0 THEN
        CVvel := 0.0;
    ELSE
        CVvel := CVvel + deltaCVvel;
    END_IF
ELSE
    // Modo normal: seguir la consigna con rampa
    IF error > 0 THEN
        // Subida de velocidad
        deltaCVvel := maxRampaSubida * cicloSegundos;
        IF CVvel + deltaCVvel > SPvel THEN
            CVvel := SPvel;
        ELSE
            CVvel := CVvel + deltaCVvel;
        END_IF
    ELSE
        // Bajada de velocidad
        deltaCVvel := -maxRampaBajada * cicloSegundos;
        IF CVvel + deltaCVvel < SPvel THEN
            CVvel := SPvel;
        ELSE
            CVvel := CVvel + deltaCVvel;
        END_IF
    END_IF
END_IF;

END_FUNCTION_BLOCK