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
    tonOil       : TON;  (* Temporizador para confirmar presión de aceite 3 s *)
    pOilConfirmed : BOOL; (* TRUE cuando pOilOk lleva >= 3 s continuo *)
    permisivos   : BOOL; (* TRUE cuando todos los permisivos están OK *)
    btnMarchaPrev : BOOL; (* Valor anterior de btnMarcha para detectar flanco *)
    flancoBtnMarcha : BOOL; (* Flanco ascendente de btnMarcha *)
END_VAR

(* ─────────────────────────────────────────────────────────────
   1. Temporizador de presión de aceite (3 s continuos)
   ───────────────────────────────────────────────────────────── *)
tonOil(IN := pOilOk, PT := T#3S);
pOilConfirmed := tonOil.Q; (* TRUE solo tras 3 s ininterrumpidos *)

(* ─────────────────────────────────────────────────────────────
   2. Evaluación de permisivos globales
   ───────────────────────────────────────────────────────────── *)
permisivos := pOilConfirmed AND tempOk AND sinAlm;

(* ─────────────────────────────────────────────────────────────
   3. Causa de bloqueo (prioridad al de número menor)
   ───────────────────────────────────────────────────────────── *)
IF NOT pOilConfirmed THEN
    causaBloqueo := 1; (* Falta presión de aceite *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Falta temperatura correcta *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Hay alarma activa *)
ELSE
    causaBloqueo := 0; (* Sin bloqueo *)
END_IF;

(* ─────────────────────────────────────────────────────────────
   4. Detección de flanco ascendente de btnMarcha
   ───────────────────────────────────────────────────────────── *)
flancoBtnMarcha := btnMarcha AND NOT btnMarchaPrev;
btnMarchaPrev   := btnMarcha;

(* ─────────────────────────────────────────────────────────────
   5. Lógica de arranque / paro del compresor
      - Arranque: flanco de btnMarcha + permisivos OK
      - Paro:     btnParo  OR  pérdida de cualquier permisivo
      - btnParo tiene prioridad sobre btnMarcha (evaluado al final)
      - El compresor NO arranca solo al recuperarse los permisivos
   ───────────────────────────────────────────────────────────── *)
IF btnParo THEN
    (* Paro con máxima prioridad *)
    comp := FALSE;
ELSIF NOT permisivos THEN
    (* Pérdida de cualquier permisivo detiene el compresor *)
    comp := FALSE;
ELSIF flancoBtnMarcha AND permisivos THEN
    (* Arranque solo en el flanco de btnMarcha con permisivos OK *)
    comp := TRUE;
END_IF;
(* Si ninguna condición aplica, comp conserva su valor anterior (memoria) *)

END_FUNCTION_BLOCK