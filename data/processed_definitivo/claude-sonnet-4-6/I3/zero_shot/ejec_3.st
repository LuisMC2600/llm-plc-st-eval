FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Causa de alarma 1 - prioridad alta   *)
    alm2 : BOOL; (* Causa de alarma 2 - prioridad media  *)
    alm3 : BOOL; (* Causa de alarma 3 - prioridad baja   *)
    ack1 : BOOL; (* Reconocimiento individual alarma 1   *)
    ack2 : BOOL; (* Reconocimiento individual alarma 2   *)
    ack3 : BOOL; (* Reconocimiento individual alarma 3   *)
END_VAR

VAR_OUTPUT
    sirena    : BOOL; (* TRUE si hay al menos una alarma activa *)
    codigoAlm : INT;  (* Código de la alarma de mayor prioridad *)
END_VAR

VAR
    mem1 : BOOL; (* Memoria retenida de alarma 1 *)
    mem2 : BOOL; (* Memoria retenida de alarma 2 *)
    mem3 : BOOL; (* Memoria retenida de alarma 3 *)
END_VAR

(* -------------------------------------------------------
   LÓGICA DE RETENCIÓN (SET/RESET con prioridad al SET)
   - SET  : la causa activa pone la memoria a TRUE
   - RESET: el ack libera la memoria SOLO si la causa
             ya desapareció (ack sin causa = reset válido)
   ------------------------------------------------------- *)

(* Alarma 1 *)
IF alm1 THEN
    mem1 := TRUE;           (* Causa presente → retener    *)
ELSIF ack1 AND NOT alm1 THEN
    mem1 := FALSE;          (* Ack válido → liberar        *)
END_IF;

(* Alarma 2 *)
IF alm2 THEN
    mem2 := TRUE;
ELSIF ack2 AND NOT alm2 THEN
    mem2 := FALSE;
END_IF;

(* Alarma 3 *)
IF alm3 THEN
    mem3 := TRUE;
ELSIF ack3 AND NOT alm3 THEN
    mem3 := FALSE;
END_IF;

(* -------------------------------------------------------
   SIRENA: activa si cualquier alarma está retenida
   ------------------------------------------------------- *)
sirena := mem1 OR mem2 OR mem3;

(* -------------------------------------------------------
   CÓDIGO DE ALARMA: prioridad alta → media → baja → 0
   ------------------------------------------------------- *)
IF mem1 THEN
    codigoAlm := 1;
ELSIF mem2 THEN
    codigoAlm := 2;
ELSIF mem3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;

END_FUNCTION_BLOCK