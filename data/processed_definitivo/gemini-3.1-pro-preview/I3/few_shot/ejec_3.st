FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Causa alarma 1 (Prioridad alta) *)
    alm2 : BOOL; (* Causa alarma 2 (Prioridad media) *)
    alm3 : BOOL; (* Causa alarma 3 (Prioridad baja) *)
    ack1 : BOOL; (* Reconocimiento alarma 1 *)
    ack2 : BOOL; (* Reconocimiento alarma 2 *)
    ack3 : BOOL; (* Reconocimiento alarma 3 *)
END_VAR
VAR_OUTPUT
    sirena : BOOL; (* Sirena general *)
    codigoAlm : INT; (* Codigo de alarma de mayor prioridad *)
END_VAR
VAR
    mem1 : BOOL; (* Memoria alarma 1 *)
    mem2 : BOOL; (* Memoria alarma 2 *)
    mem3 : BOOL; (* Memoria alarma 3 *)
END_VAR

(* Retencion de alarmas: se mantienen activas hasta recibir ack sin la causa presente *)
mem1 := alm1 OR (mem1 AND NOT ack1);
mem2 := alm2 OR (mem2 AND NOT ack2);
mem3 := alm3 OR (mem3 AND NOT ack3);

(* La sirena se enciende si hay al menos una alarma activa en memoria *)
sirena := mem1 OR mem2 OR mem3;

(* Evaluacion de prioridad para el codigo de alarma *)
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