FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL; (* Presion de aceite correcta *)
    tempOk : BOOL; (* Temperatura correcta *)
    sinAlm : BOOL; (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    comp : BOOL; (* Compresor en marcha *)
    causaBloqueo : INT; (* Causa del bloqueo *)
END_VAR
VAR
    pOilOkTimer : TON; (* Temporizador para presion de aceite *)
    btnMarchaRising : R_TRIG; (* Detector de flanco ascendente para btnMarcha *)
END_VAR

(* Evaluar el flanco ascendente de btnMarcha *)
btnMarchaRising(CLK := btnMarcha);

(* Temporizador para verificar que pOilOk este activo durante 3 segundos continuos *)
pOilOkTimer(IN := pOilOk, PT := T#3S);

(* Determinar la causa del bloqueo *)
IF NOT pOilOk THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF

(* Logica de control del compresor *)
IF btnParo THEN
    comp := FALSE; (* Prioridad al boton de paro *)
ELSIF comp THEN
    (* Mantener el compresor en marcha si todos los permisivos se cumplen *)
    IF NOT (pOilOkTimer.Q AND tempOk AND sinAlm) THEN
        comp := FALSE; (* Detener si algun permisivo se pierde *)
    END_IF
ELSE
    (* Arrancar el compresor si se presiona btnMarcha y todos los permisivos se cumplen *)
    IF btnMarchaRising.Q AND pOilOkTimer.Q AND tempOk AND sinAlm THEN
        comp := TRUE;
    END_IF
END_IF
END_FUNCTION_BLOCK