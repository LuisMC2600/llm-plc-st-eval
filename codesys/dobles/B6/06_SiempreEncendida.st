(* DOBLE DE PRUEBA B6/SiempreEncendida - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 1 *)
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL;
END_VAR
VAR_OUTPUT
    lampara : BOOL;
END_VAR
VAR
    nada : BOOL;
END_VAR
lampara := alarma;
END_FUNCTION_BLOCK
