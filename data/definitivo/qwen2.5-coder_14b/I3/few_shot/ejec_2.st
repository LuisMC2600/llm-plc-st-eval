FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Alarma de alta prioridad *)
    alm2 : BOOL; (* Alarma de media prioridad *)
    alm3 : BOOL; (* Alarma de baja prioridad *)
    ack1 : BOOL; (* Reconocimiento de alarma 1 *)
    ack2 : BOOL; (* Reconocimiento de alarma 2 *)
    ack3 : BOOL; (* Reconocimiento de alarma 3 *)
END_VAR
VAR_OUTPUT
    sirena : BOOL; (* Sirena *)
    codigoAlm : INT; (* Código de alarma *)
END_VAR
VAR
    retAlm1 : BOOL; (* Retención de alarma 1 *)
    retAlm2 : BOOL; (* Retención de alarma 2 *)
    retAlm3 : BOOL; (* Retención de alarma 3 *)
END_VAR

(* Retención de alarmas *)
IF NOT ack1 THEN
    retAlm1 := alm1;
ELSE
    retAlm1 := FALSE;
END_IF;

IF NOT ack2 THEN
    retAlm2 := alm2;
ELSE
    retAlm2 := FALSE;
END_IF;

IF NOT ack3 THEN
    retAlm3 := alm3;
ELSE
    retAlm3 := FALSE;
END_IF;

(* Determinación de la alarma de mayor prioridad *)
IF retAlm1 THEN
    codigoAlm := 1;
ELSIF retAlm2 THEN
    codigoAlm := 2;
ELSIF retAlm3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;

(* Encendido de la sirena si hay alguna alarma activa *)
sirena := retAlm1 OR retAlm2 OR retAlm3;
END_FUNCTION_BLOCK