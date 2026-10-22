(* DOBLE DE PRUEBA I6/SinHisteresis - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 2 *)
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
IF rawTemp < 0 OR rawTemp > 27648 THEN
    almSensor := TRUE;
    enfriador := FALSE;
ELSE
    almSensor := FALSE;
    tempC := INT_TO_REAL(rawTemp) / 27648.0 * 100.0;
    enfriador := tempC >= 80.0;
END_IF
END_FUNCTION_BLOCK
