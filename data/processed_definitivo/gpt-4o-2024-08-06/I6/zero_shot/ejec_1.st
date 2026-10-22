FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; // Valor de entrada de temperatura en bruto
END_VAR

VAR_OUTPUT
    tempC : REAL; // Temperatura calculada en grados Celsius
    enfriador : BOOL; // Estado del enfriador
    almSensor : BOOL; // Alarma de sensor
END_VAR

VAR
    tempC_prev : REAL; // Almacena el valor anterior de tempC para histéresis
END_VAR

// Constantes para la conversión de la señal de entrada a grados Celsius
CONST
    SCALE_FACTOR : REAL := 100.0 / 27648.0; // Factor de escala para convertir rawTemp a grados Celsius
END_CONST

// Cuerpo del bloque de función
BEGIN
    // Verificar si rawTemp está fuera de rango
    IF (rawTemp < 0) OR (rawTemp > 27648) THEN
        almSensor := TRUE; // Activar alarma de sensor
        enfriador := FALSE; // Desactivar enfriador
    ELSE
        almSensor := FALSE; // Desactivar alarma de sensor
        // Convertir rawTemp a grados Celsius
        tempC := rawTemp * SCALE_FACTOR;

        // Control del enfriador con histéresis
        IF tempC >= 80.0 THEN
            enfriador := TRUE; // Activar enfriador
        ELSIF tempC <= 75.0 THEN
            enfriador := FALSE; // Desactivar enfriador
        ELSE
            // Mantener el estado anterior del enfriador
            enfriador := enfriador;
        END_IF;
    END_IF;
END_FUNCTION_BLOCK