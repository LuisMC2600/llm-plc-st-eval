IF tempC >= 80.0 THEN
       enfriador := TRUE;
   ELSIF tempC <= 75.0 THEN
       enfriador := FALSE;
   END_IF

IF rawTemp > 27648 OR rawTemp < 0 THEN
       almSensor := TRUE;
       enfriador := FALSE; // Asegurar que el enfriador se apague
   ELSE
       almSensor := FALSE; // Asegurar que la alarma se apague cuando el valor es válido
   END_IF