FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor crudo del sensor de temperatura *)
END_VAR
VAR_OUTPUT
    tempC : REAL; (* Temperatura escalada en grados Celsius *)
    enfriador : BOOL; (* Estado del enfriador *)
    almSensor : BOOL; (* Alarma de sensor fuera de rango *)
END_VAR

(* Calculo de la temperatura escalada (0.0 a 100.0) *)
tempC := (INT_TO_REAL(rawTemp) / 27648.0) * 100.0;

(* Evaluacion de alarma por limites del sensor *)
almSensor := (rawTemp < 0) OR (rawTemp > 27648);

(* Control del enfriador con histeresis y bloqueo por alarma *)
IF almSensor THEN
    enfriador := FALSE;
ELSIF tempC >= 80.0 THEN
    enfriador := TRUE;
ELSIF tempC <= 75.0 THEN
    enfriador := FALSE;
END_IF;
END_FUNCTION_BLOCK