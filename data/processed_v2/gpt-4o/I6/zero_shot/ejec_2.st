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
    tempC_prev : REAL; // Temperatura anterior para control de histéresis
END_VAR

// Conversión de rawTemp a grados Celsius
tempC := (REAL(rawTemp) * 100.0) / 27648.0;

// Comprobación de límites de rawTemp para activar alarma
IF (rawTemp < 0) OR (rawTemp > 27648) THEN
    almSensor := TRUE;
    enfriador := FALSE; // Desactiva el enfriador si hay un error de sensor
ELSE
    almSensor := FALSE;
    
    // Control de histéresis para el enfriador
    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    ELSE
        // Mantiene el estado anterior del enfriador
        enfriador := enfriador;
    END_IF;
END_IF;
END_FUNCTION_BLOCK