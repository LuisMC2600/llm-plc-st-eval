FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor de temperatura crudo *)
END_VAR
VAR_OUTPUT
    tempC : REAL; (* Temperatura en Celsius *)
    enfriador : BOOL; (* Estado del enfriador *)
    almSensor : BOOL; (* Alarma del sensor *)
END_VAR
VAR
    tempMin : REAL := 0.0; (* Temperatura mínima *)
    tempMax : REAL := 100.0; (* Temperatura máxima *)
    rawTempMin : INT := 0; (* Valor mínimo de rawTemp *)
    rawTempMax : INT := 27648; (* Valor máximo de rawTemp *)
    histeresis : REAL := 5.0; (* Histéresis *)
END_VAR

(* Calcula la temperatura en Celsius *)
tempC := (rawTemp - rawTempMin) * (tempMax - tempMin) / (rawTempMax - rawTempMin) + tempMin;

(* Alarma del sensor si rawTemp está fuera de rango *)
almSensor := (rawTemp < rawTempMin) OR (rawTemp > rawTempMax);

(* Control del enfriador con histéresis *)
IF tempC >= 80.0 THEN
    enfriador := TRUE;
ELSIF tempC <= 75.0 THEN
    enfriador := FALSE;
END_IF;
END_FUNCTION_BLOCK