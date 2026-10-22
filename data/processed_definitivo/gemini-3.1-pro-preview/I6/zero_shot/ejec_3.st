FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; // Señal analógica cruda (0 a 27648)
END_VAR

VAR_OUTPUT
    tempC : REAL; // Temperatura escalada en grados Celsius (0.0 a 100.0)
    enfriador : BOOL; // Estado del enfriador
    almSensor : BOOL; // Alarma de sensor fuera de rango
END_VAR

// 1. Evaluación de alarma por fuera de rango
IF rawTemp < 0 OR rawTemp > 27648 THEN
    almSensor := TRUE;
ELSE
    almSensor := FALSE;
END_IF;

// 2. Acondicionamiento y escalado de la señal a REAL (0.0 - 100.0)
tempC := (INT_TO_REAL(rawTemp) / 27648.0) * 100.0;

// 3. Control del enfriador con histéresis y enclavamiento por alarma
IF almSensor THEN
    // Por seguridad, si el sensor falla, se desactiva el enfriador
    enfriador := FALSE;
ELSE
    // Lógica de histéresis
    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    END_IF;
    // Si tempC está entre 75.0 y 80.0, 'enfriador' conserva su estado anterior
END_IF;

END_FUNCTION_BLOCK