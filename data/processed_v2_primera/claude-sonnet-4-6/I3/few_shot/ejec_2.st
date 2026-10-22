FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; (* Causa de alarma 1 - prioridad alta *)
    alm2 : BOOL; (* Causa de alarma 2 - prioridad media *)
    alm3 : BOOL; (* Causa de alarma 3 - prioridad baja *)
    ack1 : BOOL; (* Reconocimiento de alarma 1 *)
    ack2 : BOOL; (* Reconocimiento de alarma 2 *)
    ack3 : BOOL; (* Reconocimiento de alarma 3 *)
END_VAR
VAR_OUTPUT
    sirena    : BOOL; (* Sirena activa si hay alguna alarma retenida *)
    codigoAlm : INT;  (* Codigo de la alarma de mayor prioridad activa *)
END_VAR
VAR
    ret1 : BOOL; (* Bit de retencion de alarma 1 *)
    ret2 : BOOL; (* Bit de retencion de alarma 2 *)
    ret3 : BOOL; (* Bit de retencion de alarma 3 *)
END_VAR

(* --- Logica de retencion --- *)
(* La alarma se activa (set) cuando aparece la causa *)
(* Se desactiva (reset) solo si la causa ya desaparecio y llega el ack *)

(* Alarma 1: set por alm1, reset por ack1 cuando alm1 ya no esta activa *)
IF alm1 THEN
    ret1 := TRUE;
ELSIF ack1 AND NOT alm1 THEN
    ret1 := FALSE;
END_IF;

(* Alarma 2: set por alm2, reset por ack2 cuando alm2 ya no esta activa *)
IF alm2 THEN
    ret2 := TRUE;
ELSIF ack2 AND NOT alm2 THEN
    ret2 := FALSE;
END_IF;

(* Alarma 3: set por alm3, reset por ack3 cuando alm3 ya no esta activa *)
IF alm3 THEN
    ret3 := TRUE;
ELSIF ack3 AND NOT alm3 THEN
    ret3 := FALSE;
END_IF;

(* --- Sirena --- *)
(* Activa si al menos una alarma esta retenida *)
sirena := ret1 OR ret2 OR ret3;

(* --- Codigo de alarma de mayor prioridad --- *)
(* Se evalua en orden descendente de prioridad *)
IF ret1 THEN
    codigoAlm := 1;
ELSIF ret2 THEN
    codigoAlm := 2;
ELSIF ret3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0; (* Sin alarmas activas *)
END_IF;

END_FUNCTION_BLOCK