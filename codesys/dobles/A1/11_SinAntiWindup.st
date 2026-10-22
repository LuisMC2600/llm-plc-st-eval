(* DOBLE DE PRUEBA A1/SinAntiWindup - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 8 *)
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
IF primero THEN
    ePrev := e;
    pvPrev := PV;
    primero := FALSE;
END_IF
d := (e - ePrev) / tMuestreo;
ePrev := e;
pvPrev := PV;
IF Ti > 0.0 THEN
    IF TRUE THEN
        I := I + e * tMuestreo;
    END_IF
    cv0 := Kp * (e + I / Ti + Td * d);
ELSE
    cv0 := Kp * (e + Td * d);
END_IF
CV := LIMIT(0.0, cv0, 100.0);
END_FUNCTION_BLOCK
