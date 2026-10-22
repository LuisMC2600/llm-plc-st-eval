```pascal
FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; // Entrada de la señal de temperatura cruda
END_VAR

VAR_OUTPUT
    tempC : REAL; // Salida de la temperatura en grados Celsius
    enfriador : BOOL; // Estado del enfriador
    almSensor : BOOL; // Alarma de sensor
END_VAR

VAR
    tempC_prev : REAL; // Variable para almacenar el valor anterior de tempC
END_VAR

// Conversión de la señal cruda a grados Celsius
tempC := (REAL(rawTemp) / 27648.0) * 100.0;

// Comprobación de límites de la señal cruda
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
```