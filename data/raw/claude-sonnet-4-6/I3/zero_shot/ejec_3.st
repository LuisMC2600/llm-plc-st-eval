```pascal
FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Causa de alarma 1 - prioridad alta   *)
    alm2 : BOOL; (* Causa de alarma 2 - prioridad media  *)
    alm3 : BOOL; (* Causa de alarma 3 - prioridad baja   *)
    ack1 : BOOL; (* Reconocimiento de alarma 1            *)
    ack2 : BOOL; (* Reconocimiento de alarma 2            *)
    ack3 : BOOL; (* Reconocimiento de alarma 3            *)
END_VAR

VAR_OUTPUT
    sirena    : BOOL; (* TRUE si hay al menos una alarma activa *)
    codigoAlm : INT;  (* Código de la alarma de mayor prioridad *)
END_VAR

VAR
    latched1 : BOOL; (* Alarma 1 retenida (latch)              *)
    latched2 : BOOL; (* Alarma 2 retenida (latch)              *)
    latched3 : BOOL; (* Alarma 3 retenida (latch)              *)
END_VAR

(* -------------------------------------------------------
   LÓGICA DE RETENCIÓN (SET/RESET con prioridad al SET)
   - Se activa (set)   cuando aparece la causa.
   - Se desactiva (reset) solo si la causa desapareció
     Y se ha pulsado el reconocimiento correspondiente.
   ------------------------------------------------------- *)

(* -- Alarma 1 -- *)
IF alm1 THEN
    latched1 := TRUE;           (* La causa activa retiene la alarma  *)
ELSIF ack1 AND NOT alm1 THEN
    latched1 := FALSE;          (* Reconocida y causa ya desaparecida *)
END_IF;

(* -- Alarma 2 -- *)
IF alm2 THEN
    latched2 := TRUE;
ELSIF ack2 AND NOT alm2 THEN
    latched2 := FALSE;
END_IF;

(* -- Alarma 3 -- *)
IF alm3 THEN
    latched3 := TRUE;
ELSIF ack3 AND NOT alm3 THEN
    latched3 := FALSE;
END_IF;

(* -------------------------------------------------------
   SIRENA: activa si cualquier alarma está retenida
   ------------------------------------------------------- *)
sirena := latched1 OR latched2 OR latched3;

(* -------------------------------------------------------
   CÓDIGO DE ALARMA: reporta la de mayor prioridad activa
   Prioridad: 1 (alta) > 2 (media) > 3 (baja) > 0 (ninguna)
   ------------------------------------------------------- *)
IF latched1 THEN
    codigoAlm := 1;
ELSIF latched2 THEN
    codigoAlm := 2;
ELSIF latched3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;

END_FUNCTION_BLOCK
```