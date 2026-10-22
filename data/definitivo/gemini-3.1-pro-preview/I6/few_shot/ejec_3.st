FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor crudo del sensor de temperatura *)
END_VAR
VAR_OUTPUT
    tempC : REAL; (* Temperatura calculada en grados Celsius *)
    enfriador : BOOL; (* Señal de activacion del enfriador *)
    almSensor : BOOL; (* Alarma de sensor fuera de rango *)
END_VAR

(* Deteccion de falla o fuera de rango del sensor *)
almSensor := (rawTemp < 0) OR (rawTemp > 27648);

(* Acondicionamiento y escalado de la señal (0-27648 a 0.0-100.0) *)
tempC := (INT_TO_REAL(rawTemp) / 27648.0) * 100.0;

(* Control del enfriador con histeresis y proteccion por alarma *)
IF almSensor THEN
    enfriador := FALSE; (* Apaga el enfriador si hay error en el sensor *)
ELSE
    IF tempC >= 80.0 THEN
        enfriador := TRUE; (* Activa por alta temperatura *)
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE; (* Desactiva al alcanzar el umbral inferior *)
    END_IF;
    (* Entre 75.0 y 80.0 conserva su estado anterior *)
END_IF;
END_FUNCTION_BLOCK