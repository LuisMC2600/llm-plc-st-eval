FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL;    (* Presion de aceite correcta *)
    tempOk : BOOL;    (* Temperatura correcta *)
    sinAlm : BOOL;    (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Boton de arranque *)
    btnParo : BOOL;   (* Boton de parada *)
END_VAR
VAR_OUTPUT
    comp : BOOL;      (* Salida del compresor *)
    causaBloqueo : INT; (* Causa de bloqueo: 1=Aceite, 2=Temp, 3=Alarma, 0=Ninguno *)
END_VAR
VAR
    tonOil : TON;     (* Temporizador para presion de aceite *)
    trigMarcha : R_TRIG; (* Detector de flanco para boton de marcha *)
    permisivosOk : BOOL; (* Estado de todos los permisivos *)
END_VAR

(* Temporizador: presion de aceite activa por 3 segundos continuos *)
tonOil(IN := pOilOk, PT := T#3S);

(* Determinacion de la causa de bloqueo con prioridad (menor numero primero) *)
IF NOT tonOil.Q THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF;

(* Evaluacion global de permisivos *)
permisivosOk := (causaBloqueo = 0);

(* Deteccion de flanco de subida del boton de marcha *)
trigMarcha(CLK := btnMarcha);

(* Logica de control del compresor (Paro prioritario y perdida de permisivos) *)
IF btnParo OR NOT permisivosOk THEN
    comp := FALSE;
ELSIF trigMarcha.Q AND permisivosOk THEN
    comp := TRUE;
END_IF;
END_FUNCTION_BLOCK