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
    tPresion : TP; (* Temporizador para presión de aceite *)
    marchaAnterior : BOOL; (* Estado anterior del botón de marcha *)
    permisivoCumplido : BOOL; (* Indica si todos los permisivos están cumplidos *)
END_VAR

(* Temporizador para la presión de aceite *)
tPresion(IN := pOilOk, PT := T#3S);

(* Determina si todos los permisivos están cumplidos *)
permisivoCumplido := tPresion.Q AND tempOk AND sinAlm;

(* Determina la causa de bloqueo *)
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
ELSIF btnMarcha AND NOT marchaAnterior AND permisivoCumplido THEN
    comp := TRUE;
END_IF;

(* Actualiza el estado anterior del botón de marcha *)
marchaAnterior := btnMarcha;
END_FUNCTION_BLOCK