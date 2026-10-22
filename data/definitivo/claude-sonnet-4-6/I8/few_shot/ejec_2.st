```pascal
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
    pOilOkConf  : BOOL; (* Presion de aceite confirmada tras 3 s *)
    permisivos  : BOOL; (* Todos los permisivos cumplidos *)
    rMarcha     : BOOL; (* Flanco ascendente de btnMarcha *)
    btnMarchaAnt : BOOL; (* Valor anterior de btnMarcha para deteccion de flanco *)
END_VAR

(* --- Temporizador de confirmacion de presion de aceite --- *)
(* Solo avanza mientras pOilOk este activa de forma continua *)
tOil(IN := pOilOk, PT := T#3S);
pOilOkConf := tOil.Q;

(* --- Evaluacion de permisivos --- *)
permisivos := pOilOkConf AND tempOk AND sinAlm;

(* --- Deteccion de flanco ascendente de btnMarcha --- *)
rMarcha := btnMarcha AND NOT btnMarchaAnt;
btnMarchaAnt := btnMarcha;

(* --- Logica de arranque y paro del compresor --- *)
(* Paro: boton de paro o perdida de cualquier permisivo            *)
(* Arranque: flanco de btnMarcha con todos los permisivos activos  *)
(* btnParo tiene prioridad sobre btnMarcha                         *)
IF btnParo OR NOT permisivos THEN
    comp := FALSE;
ELSIF rMarcha AND permisivos THEN
    comp := TRUE;
END_IF;

(* --- Causa de bloqueo: permisivo de menor numero que falta --- *)
(* Se evalua en todo momento, independientemente del estado del compresor *)
IF NOT pOilOkConf THEN
    causaBloqueo := 1; (* Falta presion de aceite confirmada *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Falta temperatura correcta *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Hay alarma activa *)
ELSE
    causaBloqueo := 0; (* Todos los permisivos OK *)
END_IF;

END_FUNCTION_BLOCK
```