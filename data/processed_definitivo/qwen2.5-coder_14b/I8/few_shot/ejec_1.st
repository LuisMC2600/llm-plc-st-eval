FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk : BOOL; (* Presión de aceite correcta *)
    tempOk : BOOL; (* Temperatura correcta *)
    sinAlm : BOOL; (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Botón de marcha *)
    btnParo : BOOL; (* Botón de paro *)
END_VAR
VAR_OUTPUT
    comp : BOOL; (* Compresor *)
    causaBloqueo : INT; (* Causa de bloqueo *)
END_VAR
VAR
    tOilOk : TP; (* Temporizador para presión de aceite *)
    marchaAnt : BOOL; (* Estado anterior del botón de marcha *)
    permisivoOk : BOOL; (* Permiso para arranque *)
END_VAR

(* Temporizador para la presión de aceite *)
tOilOk(IN := pOilOk, PT := T#3S);

(* Determinar si todos los permisivos están cumplidos *)
permisivoOk := tOilOk.Q AND tempOk AND sinAlm;

(* Determinar la causa de bloqueo *)
IF NOT pOilOk THEN
    causaBloqueo := 1;
ELSIF NOT tempOk THEN
    causaBloqueo := 2;
ELSIF NOT sinAlm THEN
    causaBloqueo := 3;
ELSE
    causaBloqueo := 0;
END_IF;

(* Control de arranque y paro del compresor *)
IF btnParo THEN
    comp := FALSE;
ELSIF btnMarcha AND NOT marchaAnt AND permisivoOk THEN
    comp := TRUE;
END_IF;

(* Guardar el estado anterior del botón de marcha *)
marchaAnt := btnMarcha;
END_FUNCTION_BLOCK