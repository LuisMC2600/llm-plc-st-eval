```pascal
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
    ret1 : BOOL; (* Alarma 1 retenida *)
    ret2 : BOOL; (* Alarma 2 retenida *)
    ret3 : BOOL; (* Alarma 3 retenida *)
END_VAR

(* --- Logica de retencion por alarma --- *)

(* Alarma 1: se activa con alm1; se libera solo si alm1 desaparecio y se reconoce *)
IF alm1 THEN
    ret1 := TRUE;
ELSIF ack1 AND NOT alm1 THEN
    ret1 := FALSE;
END_IF;

(* Alarma 2: se activa con alm2; se libera solo si alm2 desaparecio y se reconoce *)
IF alm2 THEN
    ret2 := TRUE;
ELSIF ack2 AND NOT alm2 THEN
    ret2 := FALSE;
END_IF;

(* Alarma 3: se activa con alm3; se libera solo si alm3 desaparecio y se reconoce *)
IF alm3 THEN
    ret3 := TRUE;
ELSIF ack3 AND NOT alm3 THEN
    ret3 := FALSE;
END_IF;

(* --- Sirena: activa si al menos una alarma esta retenida --- *)
sirena := ret1 OR ret2 OR ret3;

(* --- Codigo de alarma: reporta la de mayor prioridad retenida --- *)
IF ret1 THEN
    codigoAlm := 1;
ELSIF ret2 THEN
    codigoAlm := 2;
ELSIF ret3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;

END_FUNCTION_BLOCK
```