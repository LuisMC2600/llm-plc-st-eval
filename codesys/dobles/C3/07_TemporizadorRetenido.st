(* DOBLE DE PRUEBA C3/TemporizadorRetenido - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 4 *)
PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    motor : BOOL;
    lampara : BOOL;
END_VAR
VAR
    T1 : TON;
END_VAR
motor := (btnMarcha OR motor) AND NOT btnParo;
T1(IN := motor OR T1.Q, PT := T#10S);
lampara := T1.Q;
END_PROGRAM
