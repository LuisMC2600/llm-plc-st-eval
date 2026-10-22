```pascal
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk   : BOOL; (* Presión de aceite correcta *)
    tempOk   : BOOL; (* Temperatura correcta *)
    sinAlm   : BOOL; (* Sin alarmas activas *)
    btnMarcha : BOOL; (* Pulsador de marcha *)
    btnParo  : BOOL; (* Pulsador de paro *)
END_VAR

VAR_OUTPUT
    comp         : BOOL; (* Salida compresor *)
    causaBloqueo : INT;  (* 0=ninguno, 1=presión aceite, 2=temperatura, 3=alarma *)
END_VAR

VAR
    tonOil        : TON;          (* Temporizador para confirmar presión de aceite 3 s *)
    pOilConfirmed : BOOL;         (* TRUE cuando pOilOk lleva >= 3 s continuo *)
    permisivos    : BOOL;         (* TRUE cuando todos los permisivos se cumplen *)
    btnMarchaRE   : BOOL;         (* Flanco de subida de btnMarcha *)
    btnMarchaOld  : BOOL;         (* Valor anterior de btnMarcha para detectar flanco *)
END_VAR

(* ---------------------------------------------------------------
   1. Temporizador de presión de aceite
      Se reinicia cada vez que pOilOk cae a FALSE.
   --------------------------------------------------------------- *)
tonOil(IN := pOilOk, PT := T#3S);
pOilConfirmed := tonOil.Q;

(* ---------------------------------------------------------------
   2. Evaluación global de permisivos
   --------------------------------------------------------------- *)
permisivos := pOilConfirmed AND tempOk AND sinAlm;

(* ---------------------------------------------------------------
   3. Detección de flanco de subida en btnMarcha
   --------------------------------------------------------------- *)
btnMarchaRE  := btnMarcha AND NOT btnMarchaOld;
btnMarchaOld := btnMarcha;

(* ---------------------------------------------------------------
   4. Lógica de arranque / paro del compresor
      - Arranque: flanco de subida de btnMarcha con permisivos OK
                  y btnParo no activo (btnParo tiene prioridad).
      - Paro:     btnParo activo O pérdida de cualquier permisivo.
      - El compresor NO arranca solo al recuperarse los permisivos.
   --------------------------------------------------------------- *)
IF btnParo THEN
    (* Paro con prioridad máxima *)
    comp := FALSE;
ELSIF btnMarchaRE AND permisivos THEN
    (* Arranque solo en flanco de subida con todos los permisivos *)
    comp := TRUE;
ELSIF NOT permisivos THEN
    (* Pérdida de permisivo detiene el compresor *)
    comp := FALSE;
END_IF;

(* ---------------------------------------------------------------
   5. Causa de bloqueo (se evalúa siempre, independiente del estado)
      Prioridad: 1 > 2 > 3; reporta el de número menor.
   --------------------------------------------------------------- *)
IF NOT pOilConfirmed THEN
    causaBloqueo := 1; (* Falta presión de aceite *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Temperatura incorrecta *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Alarma activa *)
ELSE
    causaBloqueo := 0; (* Sin bloqueo *)
END_IF;

END_FUNCTION_BLOCK
```