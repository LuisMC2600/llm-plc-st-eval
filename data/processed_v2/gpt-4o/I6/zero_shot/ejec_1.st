FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; // Valor de entrada de la temperatura en formato entero
END_VAR

VAR_OUTPUT
    tempC : REAL; // Temperatura calculada en grados Celsius
    enfriador : BOOL; // Estado del enfriador
    almSensor : BOOL; // Alarma de sensor
END_VAR

VAR
    tempC_prev : REAL; // Valor previo de la temperatura en grados Celsius
END_VAR

// Conversión del valor de entrada a grados Celsius
tempC := (REAL(rawTemp) * 100.0) / 27648.0;

// Verificación de los límites del sensor
IF (rawTemp < 0) OR (rawTemp > 27648) THEN
    almSensor := TRUE; // Activar alarma de sensor
    enfriador := FALSE; // Desactivar enfriador
ELSE
    almSensor := FALSE; // Desactivar alarma de sensor

    // Control del enfriador con histéresis
    IF tempC >= 80.0 THEN
        enfriador := TRUE; // Activar enfriador
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE; // Desactivar enfriador
    ELSE
        // Mantener el estado actual del enfriador
        enfriador := enfriador;
    END_IF
END_IF
END_FUNCTION_BLOCK