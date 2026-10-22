FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; // Alarma de prioridad alta
    alm2 : BOOL; // Alarma de prioridad media
    alm3 : BOOL; // Alarma de prioridad baja
    ack1 : BOOL; // Reconocimiento de alarma 1
    ack2 : BOOL; // Reconocimiento de alarma 2
    ack3 : BOOL; // Reconocimiento de alarma 3
END_VAR

VAR_OUTPUT
    sirena : BOOL; // Salida para encender la sirena
    codigoAlm : INT; // Código de la alarma de mayor prioridad
END_VAR

VAR
    alm1Retenido : BOOL := FALSE; // Alarma 1 retenida
    alm2Retenido : BOOL := FALSE; // Alarma 2 retenida
    alm3Retenido : BOOL := FALSE; // Alarma 3 retenida
END_VAR

// Retención de alarmas
IF alm1 THEN
    alm1Retenido := TRUE;
END_IF

IF alm2 THEN
    alm2Retenido := TRUE;
END_IF

IF alm3 THEN
    alm3Retenido := TRUE;
END_IF

// Reconocimiento de alarmas
IF ack1 AND NOT alm1 THEN
    alm1Retenido := FALSE;
END_IF

IF ack2 AND NOT alm2 THEN
    alm2Retenido := FALSE;
END_IF

IF ack3 AND NOT alm3 THEN
    alm3Retenido := FALSE;
END_IF

// Determinación de la alarma de mayor prioridad
IF alm1Retenido THEN
    codigoAlm := 1;
    sirena := TRUE;
ELSIF alm2Retenido THEN
    codigoAlm := 2;
    sirena := TRUE;
ELSIF alm3Retenido THEN
    codigoAlm := 3;
    sirena := TRUE;
ELSE
    codigoAlm := 0;
    sirena := FALSE;
END_IF

END_FUNCTION_BLOCK