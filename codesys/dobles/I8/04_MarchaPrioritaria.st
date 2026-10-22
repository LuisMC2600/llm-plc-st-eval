(* DOBLE DE PRUEBA I8/MarchaPrioritaria - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 7 *)
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL;
    tempOk : BOOL;
    sinAlm : BOOL;
    btnMarcha : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    comp : BOOL;
    causaBloqueo : INT;
END_VAR
VAR
    tOil : TON;
    fMarcha : R_TRIG;
    oil : BOOL;
    perm : BOOL;
    lat : BOOL;
    pet : BOOL;
END_VAR
tOil(IN := pOilOk, PT := T#3S);
oil := tOil.Q;
IF NOT oil THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF
perm := causaBloqueo = 0;
fMarcha(CLK := btnMarcha);
IF fMarcha.Q AND perm THEN
    comp := TRUE;
ELSIF btnParo OR NOT perm THEN
    comp := FALSE;
END_IF
END_FUNCTION_BLOCK
