(* DOBLE DE PRUEBA I3/Correcta - NO ES CORPUS. Esperado: veredicto 1 *)
FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL;
    alm2 : BOOL;
    alm3 : BOOL;
    ack1 : BOOL;
    ack2 : BOOL;
    ack3 : BOOL;
END_VAR
VAR_OUTPUT
    sirena : BOOL;
    codigoAlm : INT;
END_VAR
VAR
    lat : ARRAY[1..3] OF BOOL;
    alm : ARRAY[1..3] OF BOOL;
    ack : ARRAY[1..3] OF BOOL;
    i : INT;
END_VAR
alm[1] := alm1; alm[2] := alm2; alm[3] := alm3;
ack[1] := ack1; ack[2] := ack2; ack[3] := ack3;
FOR i := 1 TO 3 DO
    IF alm[i] THEN
        lat[i] := TRUE;
    ELSIF ack[i] THEN
        lat[i] := FALSE;
    END_IF
END_FOR
sirena := lat[1] OR lat[2] OR lat[3];
IF lat[1] THEN codigoAlm := 1; ELSIF lat[2] THEN codigoAlm := 2; ELSIF lat[3] THEN codigoAlm := 3; ELSE codigoAlm := 0; END_IF
END_FUNCTION_BLOCK
