```pascal
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk   : BOOL; (* Presion de aceite correcta *)
    tempOk   : BOOL; (* Temperatura correcta *)
    sinAlm   : BOOL; (* Ausencia de alarmas *)
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo   : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    comp         : BOOL; (* Salida compresor *)
    causaBloqueo : INT;  (* 0=ninguno, 1=presion, 2=temperatura, 3=alarma *)
END_VAR
VAR
    tOil        : TON;  (* Temporizador presion de aceite 3 s continuos *)
    oilOk3s     : BOOL; (* TRUE cuando pOilOk lleva 3 s activa *)
    permisivos  : BOOL; (* Todos los permisivos cumplidos *)
    rMarcha     : BOOL; (* Flanco rising de btnMarcha *)
    prevMarcha  : BOOL; (* Valor anterior de btnMarcha para deteccion de flanco *)
END_VAR

(* --- Temporizador de presion de aceite: requiere 3 s continuos --- *)
tOil(IN := pOilOk, PT := T#3S);
oilOk3s := tOil.Q;

(* --- Evaluacion de permisivos globales --- *)
permisivos := oilOk3s AND tempOk AND sinAlm;

(* --- Deteccion de flanco ascendente de btnMarcha --- *)
rMarcha   := btnMarcha AND NOT prevMarcha;
prevMarcha := btnMarcha;

(* --- Logica de arranque/paro del compresor ---
   Arranque : flanco de btnMarcha con permisivos cumplidos
   Paro     : btnParo (prioridad) o perdida de cualquier permisivo
   El compresor no rearranque solo al recuperarse los permisivos *)
IF btnParo OR NOT permisivos THEN
    comp := FALSE;
ELSIF rMarcha AND permisivos THEN
    comp := TRUE;
END_IF;

(* --- Causa de bloqueo: menor numero con falta de permisivo --- *)
IF NOT oilOk3s THEN
    causaBloqueo := 1; (* Presion de aceite insuficiente o no estabilizada *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Temperatura fuera de rango *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Alarma activa *)
ELSE
    causaBloqueo := 0; (* Todos los permisivos OK *)
END_IF;

END_FUNCTION_BLOCK
```