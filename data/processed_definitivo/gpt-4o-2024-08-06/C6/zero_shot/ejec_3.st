IF tempC >= 80.0 THEN
         enfriador := TRUE;
     ELSIF tempC <= 75.0 THEN
         enfriador := FALSE;
     END_IF

IF rawTemp < 0 OR rawTemp > 27648 THEN
         almSensor := TRUE;
         enfriador := FALSE; // Asegurar que el enfriador se desactive
     ELSE
         almSensor := FALSE;
     END_IF