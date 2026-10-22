FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; // Señal analógica cruda (0 a 27648)
END_VAR

VAR_OUTPUT
    tempC : REAL; // Temperatura escalada en grados Celsius (0.0 a 100.0)
    enfriador : BOOL; // Comando de activación del enfriador
    almSensor : BOOL; // Alarma de falla o fuera de rango del sensor
END_VAR

(* 1. Evaluación de alarma por señal fuera de rango *)
IF rawTemp < 0 OR rawTemp > 27648 THEN
    almSensor := TRUE;
ELSE
    almSensor := FALSE;
END_IF;

(* 2. Acondicionamiento y escalado de la señal a grados Celsius *)
tempC := (INT_TO_REAL(rawTemp) / 27648.0) * 100.0;

(* 3. Control del enfriador con histéresis y protección por alarma *)
IF almSensor THEN
    enfriador := FALSE; // Desactiva el enfriador por seguridad si hay falla
ELSIF tempC >= 80.0 THEN
    enfriador := TRUE;  // Activa el enfriador en el umbral superior
ELSIF tempC <= 75.0 THEN
    enfriador := FALSE; // Desactiva el enfriador en el umbral inferior
END_IF;
(* Nota: Si tempC está entre > 75.0 y < 80.0, la variable 'enfriador' 
   no se reasigna, conservando así su estado actual (histéresis). *)

END_FUNCTION_BLOCK