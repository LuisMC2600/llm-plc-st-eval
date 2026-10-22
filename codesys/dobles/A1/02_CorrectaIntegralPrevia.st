(* DOBLE DE PRUEBA A1/CorrectaIntegralPrevia - NO ES CORPUS. Esperado: veredicto 1 *)
FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;
    PV : REAL;
    Kp : REAL;
    Ti : REAL;
    Td : REAL;
    ciclo : TIME;
END_VAR
VAR_OUTPUT
    CV : REAL;
END_VAR
VAR
    I : REAL;
    ePrev : REAL;
    pvPrev : REAL;
    e : REAL;
    d : REAL;
    tMuestreo : REAL;
    cv0 : REAL;
    eAnt : REAL;
    primero : BOOL := TRUE;
END_VAR
tMuestreo := TIME_TO_REAL(ciclo) / 1000.0;
e := SP - PV;
d := (e - ePrev) / tMuestreo;
ePrev := e;
IF Ti > 0.0 THEN
    cv0 := Kp * (e + I / Ti + Td * d);
    IF NOT ((cv0 >= 100.0 AND e > 0.0) OR (cv0 <= 0.0 AND e < 0.0)) THEN
        I := I + e * tMuestreo;
    END_IF
ELSE
    cv0 := Kp * (e + Td * d);
END_IF
CV := LIMIT(0.0, cv0, 100.0);
END_FUNCTION_BLOCK
