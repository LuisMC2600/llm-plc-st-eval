(* DOBLE DE PRUEBA I3/SinRetencion - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 3 *)
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
sirena := alm1 OR alm2 OR alm3;
IF alm1 THEN codigoAlm := 1; ELSIF alm2 THEN codigoAlm := 2; ELSIF alm3 THEN codigoAlm := 3; ELSE codigoAlm := 0; END_IF
END_FUNCTION_BLOCK
