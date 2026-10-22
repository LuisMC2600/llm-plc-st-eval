(* DOBLE DE PRUEBA C3/CorrectaVarLocal - NO ES CORPUS. Esperado: veredicto 1 *)
PROGRAM PRG_Conversion
VAR
    btnMarcha : BOOL;
    btnParo : BOOL;
    motor : BOOL;
    lampara : BOOL;
    T1 : TON;
END_VAR
motor := (btnMarcha OR motor) AND NOT btnParo;
T1(IN := motor, PT := T#10S);
lampara := T1.Q;
END_PROGRAM
