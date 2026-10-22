VAR
        enfriadorEstado : BOOL := FALSE;
    END_VAR

    IF tempC >= 80.0 THEN
        enfriador := TRUE;
        enfriadorEstado := TRUE;
    ELSIF tempC < 75.0 THEN
        enfriador := FALSE;
        enfriadorEstado := FALSE;
    ELSE
        enfriador := enfriadorEstado;
    END_IF