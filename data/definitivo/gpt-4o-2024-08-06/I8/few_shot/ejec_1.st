```pascal
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL; (* Presión de aceite correcta *)
    tempOk : BOOL; (* Temperatura correcta *)
    sinAlm : BOOL; (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Botón de marcha *)
    btnParo : BOOL; (* Botón de paro *)
END_VAR
VAR_OUTPUT
    comp : BOOL; (* Compresor en marcha *)
    causaBloqueo : INT; (* Causa de bloqueo *)
END_VAR
VAR
    pOilOkTimer : TON; (* Temporizador para presión de aceite *)
    btnMarchaMem : BOOL; (* Memoria del estado del botón de marcha *)
    btnMarchaRising : BOOL; (* Detección de flanco ascendente del botón de marcha *)
END_VAR

(* Detección de flanco ascendente del botón de marcha *)
btnMarchaRising := btnMarcha AND NOT btnMarchaMem;
btnMarchaMem := btnMarcha;

(* Temporizador para verificar presión de aceite durante 3 segundos continuos *)
pOilOkTimer(IN := pOilOk, PT := T#3S);

(* Determinación de la causa de bloqueo *)
IF NOT pOilOkTimer.Q THEN
    causaBloqueo := 1; (* Falta presión de aceite *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Falta temperatura correcta *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Alarma activa *)
ELSE
    causaBloqueo := 0; (* Ningún bloqueo *)
END_IF

(* Lógica de control del compresor *)
IF btnParo THEN
    comp := FALSE; (* Parar compresor si se pulsa el botón de paro *)
ELSIF comp THEN
    IF causaBloqueo <> 0 THEN
        comp := FALSE; (* Parar compresor si se pierde algún permisivo *)
    END_IF
ELSE
    IF btnMarchaRising AND (causaBloqueo = 0) THEN
        comp := TRUE; (* Arrancar compresor si se pulsa el botón de marcha y no hay bloqueos *)
    END_IF
END_IF

END_FUNCTION_BLOCK
```