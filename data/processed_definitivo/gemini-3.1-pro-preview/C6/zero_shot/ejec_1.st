IF tempC >= 75.0 THEN
         enfriador := TRUE;
     ELSIF tempC <= 80.0 THEN
         enfriador := FALSE;
     END_IF

IF tempC >= 80.0 THEN
           enfriador := TRUE;
       ELSIF tempC <= 75.0 THEN
           enfriador := FALSE;
       END_IF

IF rawTemp > 27648 THEN
         almSensor := TRUE;
     END_IF

IF almSensor THEN
           enfriador := FALSE;
       END_IF;