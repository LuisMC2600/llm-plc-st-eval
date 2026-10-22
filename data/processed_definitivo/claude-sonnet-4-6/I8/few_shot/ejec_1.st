FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk   : BOOL; (* Presion de aceite correcta *)
    tempOk   : BOOL; (* Temperatura correcta *)
    sinAlm   : BOOL; (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo  : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    comp         : BOOL; (* Salida compresor *)
    causaBloqueo : INT;  (* 0=ninguno, 1=presion, 2=temperatura, 3=alarma *)
END_VAR
VAR
    tOil        : TON;  (* Temporizador presion de aceite 3 s continuos *)
    pOilOkConf  : BOOL; (* Presion de aceite confirmada 3 s *)
    permisivos  : BOOL; (* Todos los permisivos cumplidos *)
    rMarcha     : BOOL; (* Flanco ascendente btnMarcha *)
    btnMarchaPrev : BOOL; (* Valor anterior de btnMarcha para deteccion de flanco *)
END_VAR

(* --- Temporizador de confirmacion de presion de aceite --- *)
(* Solo cuenta mientras pOilOk este activa; se reinicia si cae *)
tOil(IN := pOilOk, PT := T#3S);
pOilOkConf := tOil.Q;

(* --- Evaluacion de permisivos globales --- *)
permisivos := pOilOkConf AND tempOk AND sinAlm;

(* --- Deteccion de flanco ascendente de btnMarcha --- *)
rMarcha := btnMarcha AND NOT btnMarchaPrev;

(* --- Logica de arranque/paro del compresor --- *)
(* Prioridad: paro > marcha                        *)
(* Arranque: flanco de btnMarcha con permisivos OK *)
(* Paro: btnParo o perdida de cualquier permisivo  *)
IF btnParo OR NOT permisivos THEN
    comp := FALSE;
ELSIF rMarcha AND permisivos THEN
    comp := TRUE;
END_IF;

(* --- Memoria del estado anterior de btnMarcha --- *)
btnMarchaPrev := btnMarcha;

(* --- Causa de bloqueo: menor numero con falta --- *)
(* Se evalua siempre, independientemente del estado del compresor *)
IF NOT pOilOkConf THEN
    causaBloqueo := 1; (* Presion de aceite insuficiente o no confirmada *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Temperatura incorrecta *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Alarma activa *)
ELSE
    causaBloqueo := 0; (* Todos los permisivos OK *)
END_IF;

END_FUNCTION_BLOCK