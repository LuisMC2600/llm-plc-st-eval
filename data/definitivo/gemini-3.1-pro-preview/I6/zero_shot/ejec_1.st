```iecst
FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; // Señal analógica cruda del sensor (0 a 27648)
END_VAR

VAR_OUTPUT
    tempC : REAL; // Temperatura escalada en grados Celsius (0.0 a 100.0)
    enfriador : BOOL; // Comando de activación del enfriador
    almSensor : BOOL; // Alarma de sensor fuera de rango
END_VAR

// 1. Acondicionamiento y escalado de la señal
// Se convierte el valor entero a real y se escala al rango 0.0 - 100.0
tempC := (INT_TO_REAL(rawTemp) / 27648.0) * 100.0;

// 2. Detección de fallas del sensor (fuera de rango)
IF rawTemp < 0 OR rawTemp > 27648 THEN
    almSensor := TRUE;
ELSE
    almSensor := FALSE;
END_IF;

// 3. Control del enfriador con histéresis y seguridad
IF almSensor THEN
    // Por seguridad, si el sensor falla, se desactiva el enfriador
    enfriador := FALSE;
ELSIF tempC >= 80.0 THEN
    // Activar enfriador si alcanza o supera el umbral superior
    enfriador := TRUE;
ELSIF tempC <= 75.0 THEN
    // Desactivar enfriador si desciende al umbral inferior o menos
    enfriador := FALSE;
END_IF;
// Nota: Si tempC está entre 75.0 y 80.0, no se ejecuta ninguna condición, 
// por lo que 'enfriador' conserva su estado anterior (histéresis).

END_FUNCTION_BLOCK
```