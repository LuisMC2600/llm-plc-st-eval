FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Causa de alarma 1 (Prioridad alta) *)
    alm2 : BOOL; (* Causa de alarma 2 (Prioridad media) *)
    alm3 : BOOL; (* Causa de alarma 3 (Prioridad baja) *)
    ack1 : BOOL; (* Reconocimiento alarma 1 *)
    ack2 : BOOL; (* Reconocimiento alarma 2 *)
    ack3 : BOOL; (* Reconocimiento alarma 3 *)
END_VAR
VAR_OUTPUT
    sirena : BOOL; (* Sirena activa si hay alguna alarma *)
    codigoAlm : INT; (* Codigo de alarma de mayor prioridad (1-3, 0 si no hay) *)
END_VAR
VAR
    latch1 : BOOL; (* Memoria de alarma 1 *)
    latch2 : BOOL; (* Memoria de alarma 2 *)
    latch3 : BOOL; (* Memoria de alarma 3 *)
END_VAR

(* Retencion de alarmas: se mantienen activas hasta recibir ack sin la causa presente *)
latch1 := alm1 OR (latch1 AND NOT ack1);
latch2 := alm2 OR (latch2 AND NOT ack2);
latch3 := alm3 OR (latch3 AND NOT ack3);

(* La sirena se enciende si cualquier alarma esta retenida *)
sirena := latch1 OR latch2 OR latch3;

(* Evaluacion de prioridad para el codigo de alarma *)
IF latch1 THEN
    codigoAlm := 1;
ELSIF latch2 THEN
    codigoAlm := 2;
ELSIF latch3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;
END_FUNCTION_BLOCK