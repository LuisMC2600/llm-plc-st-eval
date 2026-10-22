```pascal
FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT;  // Entrada de temperatura cruda (0-27648)
END_VAR

VAR_OUTPUT
    tempC : REAL;   // Temperatura en grados Celsius (0.0-100.0)
    enfriador : BOOL;  // Estado del enfriador (TRUE/FALSE)
    almSensor : BOOL;  // Alarma del sensor (TRUE/FALSE)
END_VAR

VAR
    tempCPrev : REAL;  // Valor previo de temperatura en Celsius
    enfriadorPrev : BOOL;  // Estado previo del enfriador
END_VAR

// Calculo de la temperatura en Celsius
IF rawTemp >= 0 AND rawTemp <= 27648 THEN
    tempC := rawTemp * 100.0 / 27648.0;
    almSensor := FALSE;
ELSE
    tempC := 0.0;
    almSensor := TRUE;
END_IF;

// Control del enfriador con histéresis
IF tempC >= 80.0 THEN
    enfriador := TRUE;
ELSIF tempC <= 75.0 THEN
    enfriador := FALSE;
ELSE
    enfriador := enfriadorPrev;  // Mantener el estado anterior si está en el rango de histéresis
END_IF;

// Actualizar el estado previo del enfriador
enfriadorPrev := enfriador;

END_FUNCTION_BLOCK
```