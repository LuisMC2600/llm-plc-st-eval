FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Alarma 1 - Prioridad alta *)
    alm2 : BOOL; (* Alarma 2 - Prioridad media *)
    alm3 : BOOL; (* Alarma 3 - Prioridad baja *)
    ack1 : BOOL; (* Reconocimiento alarma 1 *)
    ack2 : BOOL; (* Reconocimiento alarma 2 *)
    ack3 : BOOL; (* Reconocimiento alarma 3 *)
END_VAR
VAR_OUTPUT
    sirena : BOOL; (* Sirena activa *)
    codigoAlm : INT; (* Codigo de alarma activa de mayor prioridad *)
END_VAR
VAR
    mem1 : BOOL; (* Memoria de alarma 1 *)
    mem2 : BOOL; (* Memoria de alarma 2 *)
    mem3 : BOOL; (* Memoria de alarma 3 *)
END_VAR

(* Retencion de alarmas: se mantienen hasta que desaparece la causa y se reconocen *)
mem1 := alm1 OR (mem1 AND NOT ack1);
mem2 := alm2 OR (mem2 AND NOT ack2);
mem3 := alm3 OR (mem3 AND NOT ack3);

(* La sirena se enciende si cualquier alarma esta en memoria *)
sirena := mem1 OR mem2 OR mem3;

(* Determinacion del codigo de alarma por prioridad *)
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