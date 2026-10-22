```pascal
FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor crudo del sensor: 0..27648 -> 0.0..100.0 °C *)
END_VAR
VAR_OUTPUT
    tempC     : REAL; (* Temperatura calculada en grados Celsius *)
    enfriador : BOOL; (* Salida del enfriador *)
    almSensor : BOOL; (* Alarma de sensor fuera de rango *)
END_VAR

(* Verificar rango valido del sensor *)
IF rawTemp < 0 OR rawTemp > 27648 THEN
    almSensor := TRUE;
    enfriador := FALSE; (* Enfriador desactivado por fallo de sensor *)
ELSE
    almSensor := FALSE;

    (* Conversion lineal: tempC = rawTemp * 100.0 / 27648.0 *)
    tempC := INT_TO_REAL(rawTemp) * 100.0 / 27648.0;

    (* Control con histeresis: enciende >= 80.0, apaga <= 75.0 *)
    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    (* Entre 75.0 y 80.0 exclusivo: conserva el estado anterior *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK
```