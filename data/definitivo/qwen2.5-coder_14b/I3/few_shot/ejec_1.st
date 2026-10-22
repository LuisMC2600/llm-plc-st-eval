FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Alarma de prioridad alta *)
    alm2 : BOOL; (* Alarma de prioridad media *)
    alm3 : BOOL; (* Alarma de prioridad baja *)
    ack1 : BOOL; (* Reconocimiento de alarma 1 *)
    ack2 : BOOL; (* Reconocimiento de alarma 2 *)
    ack3 : BOOL; (* Reconocimiento de alarma 3 *)
END_VAR
VAR_OUTPUT
    sirena : BOOL; (* Sirena *)
    codigoAlm : INT; (* Código de la alarma de mayor prioridad *)
END_VAR
VAR
    alm1Retenido : BOOL; (* Alarma 1 retenida *)
    alm2Retenido : BOOL; (* Alarma 2 retenido *)
    alm3Retenido : BOOL; (* Alarma 3 retenido *)
END_VAR

(* Retención de alarmas *)
IF NOT alm1 AND ack1 THEN
    alm1Retenido := FALSE;
END_IF
IF NOT alm2 AND ack2 THEN
    alm2Retenido := FALSE;
END_IF
IF NOT alm3 AND ack3 THEN
    alm3Retenido := FALSE;
END_IF

IF alm1 THEN
    alm1Retenido := TRUE;
END_IF
IF alm2 THEN
    alm2Retenido := TRUE;
END_IF
IF alm3 THEN
    alm3Retenido := TRUE;
END_IF

(* Determinación de la alarma de mayor prioridad *)
IF alm1Retenido THEN
    sirena := TRUE;
    codigoAlm := 1;
ELSIF alm2Retenido THEN
    sirena := TRUE;
    codigoAlm := 2;
ELSIF alm3Retenido THEN
    sirena := TRUE;
    codigoAlm := 3;
ELSE
    sirena := FALSE;
    codigoAlm := 0;
END_IF
END_FUNCTION_BLOCK