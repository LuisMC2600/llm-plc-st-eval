```pascal
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
    causaBloqueo : INT; (* Causa de bloqueo *)
END_VAR
VAR
    pOilOkTimer : TON; (* Temporizador para presion de aceite *)
    btnMarchaMem : BOOL; (* Memoria de estado del boton de marcha *)
    permisivosOk : BOOL; (* Todos los permisivos estan activos *)
END_VAR

(* Temporizador para verificar presion de aceite durante 3 segundos *)
pOilOkTimer(IN := pOilOk, PT := T#3S);

(* Verificar si todos los permisivos estan activos *)
permisivosOk := pOilOkTimer.Q AND tempOk AND sinAlm;

(* Logica de arranque y paro del compresor *)
IF btnParo THEN
    comp := FALSE; (* Parar compresor si se pulsa btnParo *)
ELSIF NOT comp AND NOT btnMarchaMem AND btnMarcha AND permisivosOk THEN
    comp := TRUE; (* Arrancar compresor si se pulsa btnMarcha y permisivos estan activos *)
END_IF

(* Actualizar memoria del estado del boton de marcha *)
btnMarchaMem := btnMarcha;

(* Determinar la causa de bloqueo *)
IF NOT pOilOk THEN
    causaBloqueo := 1; (* Bloqueo por presion de aceite *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Bloqueo por temperatura *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Bloqueo por alarma activa *)
ELSE
    causaBloqueo := 0; (* No hay bloqueo *)
END_IF
END_FUNCTION_BLOCK
```