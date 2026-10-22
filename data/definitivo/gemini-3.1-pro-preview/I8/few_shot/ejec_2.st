FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL; (* Presion de aceite *)
    tempOk : BOOL; (* Temperatura correcta *)
    sinAlm : BOOL; (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Boton de arranque *)
    btnParo : BOOL; (* Boton de parada *)
END_VAR
VAR_OUTPUT
    comp : BOOL; (* Mando del compresor *)
    causaBloqueo : INT; (* Codigo de permisivo faltante *)
END_VAR
VAR
    tOil : TON; (* Temporizador de presion de aceite *)
    trigMarcha : R_TRIG; (* Detector de flanco de marcha *)
    permisivosOk : BOOL; (* Estado de todos los permisivos *)
END_VAR

(* Temporizador para validar la presion de aceite por 3s continuos *)
tOil(IN := pOilOk, PT := T#3S);

(* Deteccion de flanco de subida del boton de marcha *)
trigMarcha(CLK := btnMarcha);

(* Evaluacion general de permisivos *)
permisivosOk := tOil.Q AND tempOk AND sinAlm;

(* Logica de arranque y parada (prioridad al paro y a la perdida de permisivos) *)
IF btnParo OR NOT permisivosOk THEN
    comp := FALSE;
ELSIF trigMarcha.Q AND permisivosOk THEN
    comp := TRUE;
END_IF;

(* Determinacion de la causa de bloqueo (prioridad al numero menor) *)
IF NOT tOil.Q THEN
    causaBloqueo := 1; (* Falta presion de aceite *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Falta temperatura correcta *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Alarma activa *)
ELSE
    causaBloqueo := 0; (* Todos los permisivos OK *)
END_IF;
END_FUNCTION_BLOCK