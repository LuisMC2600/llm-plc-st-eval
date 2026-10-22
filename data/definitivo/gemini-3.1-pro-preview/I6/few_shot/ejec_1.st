FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor crudo del sensor (0-27648) *)
END_VAR
VAR_OUTPUT
    tempC : REAL; (* Temperatura en grados Celsius (0.0-100.0) *)
    enfriador : BOOL; (* Estado del enfriador *)
    almSensor : BOOL; (* Alarma de sensor fuera de rango *)
END_VAR

(* Evaluacion de limites para la alarma del sensor *)
almSensor := (rawTemp < 0) OR (rawTemp > 27648);

(* Escalado de la señal analogica *)
tempC := INT_TO_REAL(rawTemp) * 100.0 / 27648.0;

(* Control del enfriador con histeresis y proteccion por alarma *)
IF almSensor THEN
    enfriador := FALSE;
ELSIF tempC >= 80.0 THEN
    enfriador := TRUE;
ELSIF tempC <= 75.0 THEN
    enfriador := FALSE;
END_IF;
END_FUNCTION_BLOCK