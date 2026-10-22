FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor raw de temperatura *)
END_VAR
VAR_OUTPUT
    tempC : REAL; (* Temperatura en grados Celsius *)
    enfriador : BOOL; (* Estado del enfriador *)
    almSensor : BOOL; (* Alarma de sensor *)
END_VAR
VAR
    tempMin : REAL := 0.0; (* Temperatura mínima *)
    tempMax : REAL := 100.0; (* Temperatura máxima *)
    rawMin : INT := 0; (* Valor raw mínimo *)
    rawMax : INT := 27648; (* Valor raw máximo *)
    tempThresholdHigh : REAL := 80.0; (* Umbral alto para activar el enfriador *)
    tempThresholdLow : REAL := 75.0; (* Umbral bajo para desactivar el enfriador *)
END_VAR

(* Conversión de rawTemp a temperatura en Celsius *)
IF rawTemp < rawMin OR rawTemp > rawMax THEN
    almSensor := TRUE;
    tempC := 0.0;
    enfriador := FALSE;
ELSE
    almSensor := FALSE;
    tempC := (rawTemp - rawMin) * (tempMax - tempMin) / (rawMax - rawMin) + tempMin;
    (* Control del enfriador con histéresis *)
    IF tempC >= tempThresholdHigh THEN
        enfriador := TRUE;
    ELSIF tempC <= tempThresholdLow THEN
        enfriador := FALSE;
    END_IF;
END_IF;
END_FUNCTION_BLOCK