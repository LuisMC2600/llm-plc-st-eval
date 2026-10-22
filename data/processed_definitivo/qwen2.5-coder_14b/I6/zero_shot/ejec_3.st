FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; // Entrada de temperatura cruda (0 a 27648)
END_VAR

VAR_OUTPUT
    tempC : REAL; // Temperatura en grados Celsius (0.0 a 100.0)
    enfriador : BOOL; // Estado del enfriador (TRUE: activado, FALSE: desactivado)
    almSensor : BOOL; // Estado de la alarma del sensor (TRUE: activada, FALSE: desactivada)
END_VAR

VAR
    tempCPrev : REAL; // Temperatura anterior para la histéresis
    enfriadorPrev : BOOL; // Estado anterior del enfriador para la histéresis
END_VAR

// Calcula la temperatura en grados Celsius
IF rawTemp < 0 OR rawTemp > 27648 THEN
    tempC := 0.0;
    almSensor := TRUE;
    enfriador := FALSE;
ELSE
    tempC := rawTemp / 276.48; // Conversión de 0-27648 a 0.0-100.0 grados Celsius
    almSensor := FALSE;
    
    // Control del enfriador con histéresis
    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    ELSE
        enfriador := enfriadorPrev; // Mantener el estado anterior si está en la zona de histéresis
    END_IF
END_IF

// Actualiza el estado anterior del enfriador
enfriadorPrev := enfriador;