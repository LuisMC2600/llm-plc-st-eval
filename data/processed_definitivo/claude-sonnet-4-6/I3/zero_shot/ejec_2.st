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
    mem1 : BOOL; (* Memoria retenida de alarma 1 *)
    mem2 : BOOL; (* Memoria retenida de alarma 2 *)
    mem3 : BOOL; (* Memoria retenida de alarma 3 *)
END_VAR

(* ── Lógica de retención (set/reset con prioridad al set) ── *)

(* Alarma 1: se activa con alm1; se borra solo si ack1=TRUE y alm1=FALSE *)
IF alm1 THEN
    mem1 := TRUE;
ELSIF ack1 AND NOT alm1 THEN
    mem1 := FALSE;
END_IF;

(* Alarma 2: se activa con alm2; se borra solo si ack2=TRUE y alm2=FALSE *)
IF alm2 THEN
    mem2 := TRUE;
ELSIF ack2 AND NOT alm2 THEN
    mem2 := FALSE;
END_IF;

(* Alarma 3: se activa con alm3; se borra solo si ack3=TRUE y alm3=FALSE *)
IF alm3 THEN
    mem3 := TRUE;
ELSIF ack3 AND NOT alm3 THEN
    mem3 := FALSE;
END_IF;

(* ── Sirena: encendida si cualquier alarma está retenida ── *)
sirena := mem1 OR mem2 OR mem3;

(* ── Código de alarma: mayor prioridad presente ── *)
IF mem1 THEN
    codigoAlm := 1;
ELSIF mem2 THEN
    codigoAlm := 2;
ELSIF mem3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0; (* Sin alarmas activas *)
END_IF;

END_FUNCTION_BLOCK