FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL;    (* Presion de aceite correcta *)
    tempOk : BOOL;    (* Temperatura correcta *)
    sinAlm : BOOL;    (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Boton de arranque *)
    btnParo : BOOL;   (* Boton de parada *)
END_VAR
VAR_OUTPUT
    comp : BOOL;        (* Mando del compresor *)
    causaBloqueo : INT; (* Codigo de permisivo faltante *)
END_VAR
VAR
    tOil : TON;           (* Temporizador de presion de aceite *)
    trigMarcha : R_TRIG;  (* Detector de flanco para el arranque *)
    permisivosOk : BOOL;  (* Estado global de permisivos *)
END_VAR

(* Validacion de presion de aceite continua por 3 segundos *)
tOil(IN := pOilOk, PT := T#3S);

(* Determinacion de la causa de bloqueo (prioridad al numero menor) *)
IF NOT tOil.Q THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF;

(* Todos los permisivos se cumplen si no hay causa de bloqueo *)
permisivosOk := (causaBloqueo = 0);

(* Deteccion de pulsacion del boton de marcha (transicion FALSE a TRUE) *)
trigMarcha(CLK := btnMarcha);

(* Control de marcha y paro del compresor (Paro prioritario) *)
IF btnParo OR NOT permisivosOk THEN
    comp := FALSE;
ELSIF trigMarcha.Q THEN
    comp := TRUE;
END_IF;
END_FUNCTION_BLOCK