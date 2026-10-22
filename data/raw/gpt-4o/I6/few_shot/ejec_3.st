```pascal
FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Señal de temperatura en bruto *)
END_VAR
VAR_OUTPUT
    tempC : REAL; (* Temperatura en grados Celsius *)
    enfriador : BOOL; (* Estado del enfriador *)
    almSensor : BOOL; (* Alarma del sensor *)
END_VAR
VAR
    tempC_prev : REAL; (* Temperatura anterior para histéresis *)
END_VAR

(* Verificar si la señal de temperatura está fuera de rango *)
IF (rawTemp < 0) OR (rawTemp > 27648) THEN
    almSensor := TRUE;
    enfriador := FALSE;
ELSE
    almSensor := FALSE;
    
    (* Convertir la señal de temperatura en bruto a grados Celsius *)
    tempC := (REAL(rawTemp) * 100.0) / 27648.0;
    
    (* Control del enfriador con histéresis *)
    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    ELSE
        enfriador := enfriador; (* Mantener el estado actual *)
    END_IF;
END_IF;
END_FUNCTION_BLOCK
```