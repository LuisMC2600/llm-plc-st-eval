```pascal
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

// Calculo de la temperatura en grados Celsius
IF rawTemp < 0 OR rawTemp > 27648 THEN
    tempC := 0.0;
    almSensor := TRUE;
    enfriador := FALSE;
ELSE
    tempC := rawTemp / 276.48;
    almSensor := FALSE;
    
    // Control del enfriador con histéresis
    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    ELSE
        enfriador := enfriadorPrev; // Mantener el estado anterior
    END_IF
END_IF

// Actualizar el estado anterior del enfriador
enfriadorPrev := enfriador;
```

Este código implementa un FUNCTION_BLOCK en Structured Text (ST) conforme al estándar IEC 61131-3 para controlar una señal de temperatura. La entrada `rawTemp` se convierte a una temperatura en grados Celsius (`tempC`). El enfriador se activa cuando `tempC` es mayor o igual a 80.0 y se desactiva cuando es menor o igual a 75.0, con una histéresis para evitar oscilaciones. Si `rawTemp` está fuera del rango válido (menor que 0 o mayor que 27648), se activa la alarma del sensor (`almSensor`) y se desactiva el enfriador.