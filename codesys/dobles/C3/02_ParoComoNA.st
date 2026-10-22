(* DOBLE DE PRUEBA C3/ParoComoNA - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 1 *)
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
motor := (btnMarcha OR motor) AND btnParo;
T1(IN := motor, PT := T#10S);
lampara := T1.Q;
END_PROGRAM
