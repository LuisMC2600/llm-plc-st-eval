```pascal
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;       // Consigna de velocidad deseada
    paroRapido : BOOL;  // Indica si se debe activar el paro rápido
    ciclo : TIME;       // Período de ejecución del bloque
END_VAR

VAR_OUTPUT
    CVvel : REAL;       // Consigna de velocidad actual
END_VAR

VAR
    lastCVvel : REAL;   // Valor de CVvel en la iteración anterior
    rampaSubida : REAL := 10.0;  // Pendiente de subida en puntos porcentuales por segundo
    rampaBajada : REAL := 20.0;  // Pendiente de bajada en puntos porcentuales por segundo
    rampaParoRapido : REAL := 40.0;  // Pendiente de paro rápido en puntos porcentuales por segundo
    tiempoCiclo : TIME;  // Tiempo transcurrido desde la última iteración
END_VAR

// Calcular el tiempo transcurrido desde la última iteración
tiempoCiclo := ciclo;

// Verificar si se debe activar el paro rápido
IF paroRapido THEN
    // Descender CVvel hacia 0.0 con una pendiente de 40.0 puntos porcentuales por segundo
    CVvel := MAX(0.0, lastCVvel - rampaParoRapido * REAL(tiempoCiclo / T#1s));
ELSE
    // Calcular la nueva CVvel según la consigna SPvel
    IF SPvel > lastCVvel THEN
        // Subida de velocidad
        CVvel := MIN(SPvel, lastCVvel + rampaSubida * REAL(tiempoCiclo / T#1s));
    ELSE
        // Bajada de velocidad
        CVvel := MAX(SPvel, lastCVvel - rampaBajada * REAL(tiempoCiclo / T#1s));
    END_IF;
END_IF;

// Actualizar el valor de lastCVvel para la próxima iteración
lastCVvel := CVvel;
```

Este código implementa un generador de consigna de velocidad con rampa en un FUNCTION_BLOCK llamado `FB_Rampa`. La salida `CVvel` sigue a la consigna `SPvel` con las pendientes especificadas, y en caso de activación de `paroRapido`, `CVvel` descenderá hacia 0.0 con una pendiente de 40.0 puntos porcentuales por segundo.