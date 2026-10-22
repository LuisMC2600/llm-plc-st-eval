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
    btnMarchaPrev : BOOL; (* Valor anterior de btnMarcha para detectar flanco *)
    flankMarcha  : BOOL; (* Flanco ascendente de btnMarcha *)
    permisivos   : BOOL; (* TRUE si todos los permisivos se cumplen *)
END_VAR

(* ─────────────────────────────────────────────────────────────
   1. Temporizador de presión de aceite (3 s continuos)
   ───────────────────────────────────────────────────────────── *)
tonOil(IN := pOilOk, PT := T#3S);
pOilConfirmed := tonOil.Q; (* TRUE solo tras 3 s ininterrumpidos *)

(* ─────────────────────────────────────────────────────────────
   2. Evaluación de permisivos
   ───────────────────────────────────────────────────────────── *)
permisivos := pOilConfirmed AND tempOk AND sinAlm;

(* ─────────────────────────────────────────────────────────────
   3. Causa de bloqueo (prioridad al de número menor)
   ───────────────────────────────────────────────────────────── *)
IF NOT pOilConfirmed THEN
    causaBloqueo := 1; (* Falta presión de aceite *)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; (* Temperatura incorrecta *)
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; (* Alarma activa *)
ELSE
    causaBloqueo := 0; (* Sin bloqueo *)
END_IF;

(* ─────────────────────────────────────────────────────────────
   4. Detección de flanco ascendente de btnMarcha
   ───────────────────────────────────────────────────────────── *)
flankMarcha := btnMarcha AND NOT btnMarchaPrev;

(* ─────────────────────────────────────────────────────────────
   5. Lógica de arranque / paro del compresor
      - btnParo tiene prioridad sobre btnMarcha
      - Paro también ante pérdida de cualquier permisivo
      - Arranque solo en flanco de btnMarcha con permisivos OK
      - No rearranque automático al recuperar permisivos
   ───────────────────────────────────────────────────────────── *)
IF btnParo OR NOT permisivos THEN
    (* Paro forzado: pulsador de paro o pérdida de permisivo *)
    comp := FALSE;
ELSIF flankMarcha AND permisivos THEN
    (* Arranque: flanco de marcha con todos los permisivos *)
    comp := TRUE;
END_IF;
(* Si ninguna condición aplica, comp mantiene su estado (enclavamiento) *)

(* ─────────────────────────────────────────────────────────────
   6. Actualización del valor previo de btnMarcha
   ───────────────────────────────────────────────────────────── *)
btnMarchaPrev := btnMarcha;