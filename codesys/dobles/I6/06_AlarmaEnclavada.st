(* DOBLE DE PRUEBA I6/AlarmaEnclavada - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 4 *)
FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT;
END_VAR
VAR_OUTPUT
    tempC : REAL;
    enfriador : BOOL;
    almSensor : BOOL;
END_VAR
VAR
    almPrev : BOOL;
END_VAR
almPrev := almSensor;
IF rawTemp < 0 OR rawTemp > 27648 THEN
    almSensor := TRUE;
    enfriador := FALSE;
ELSE
    almSensor := FALSE;
    tempC := INT_TO_REAL(rawTemp) / 27648.0 * 100.0;
    IF tempC >= 80.0 THEN
        enfriador := TRUE;
    ELSIF tempC <= 75.0 THEN
        enfriador := FALSE;
    END_IF
END_IF
almSensor := almSensor OR almPrev;
END_FUNCTION_BLOCK
