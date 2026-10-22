FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Señal de demanda de bombeo *)
    falla1  : BOOL; (* Falla de bomba 1 *)
    falla2  : BOOL; (* Falla de bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1  : BOOL; (* Salida de bomba 1 *)
    bomba2  : BOOL; (* Salida de bomba 2 *)
    almFalla : BOOL; (* Alarma de falla en bomba principal *)
END_VAR
VAR
    principal1   : BOOL := TRUE;  (* TRUE = bomba1 es principal, FALSE = bomba2 es principal *)
    demandaAnterior : BOOL := FALSE; (* Estado previo de demanda para detectar flanco ascendente *)
    flanco       : BOOL; (* Flanco ascendente de demanda *)
END_VAR

(* Detectar flanco ascendente de demanda *)
flanco := demanda AND NOT demandaAnterior;

(* En cada nuevo flanco de demanda, alternar el rol de principal *)
IF flanco THEN
    principal1 := NOT principal1;
END_IF;

(* Guardar estado actual de demanda para el siguiente ciclo *)
demandaAnterior := demanda;

(* Lógica de arranque y alarma *)
IF NOT demanda THEN
    (* Sin demanda: ambas bombas detenidas, sin alarma *)
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;

ELSIF principal1 THEN
    (* Bomba 1 es la principal *)
    IF NOT falla1 THEN
        (* Principal sin falla: funciona bomba1 *)
        bomba1   := TRUE;
        bomba2   := FALSE;
        almFalla := FALSE;
    ELSIF NOT falla2 THEN
        (* Principal con falla, respaldo sin falla: funciona bomba2 *)
        bomba1   := FALSE;
        bomba2   := TRUE;
        almFalla := TRUE;
    ELSE
        (* Ambas con falla: ninguna funciona, alarma activa *)
        bomba1   := FALSE;
        bomba2   := FALSE;
        almFalla := TRUE;
    END_IF;

ELSE
    (* Bomba 2 es la principal *)
    IF NOT falla2 THEN
        (* Principal sin falla: funciona bomba2 *)
        bomba1   := FALSE;
        bomba2   := TRUE;
        almFalla := FALSE;
    ELSIF NOT falla1 THEN
        (* Principal con falla, respaldo sin falla: funciona bomba1 *)
        bomba1   := TRUE;
        bomba2   := FALSE;
        almFalla := TRUE;
    ELSE
        (* Ambas con falla: ninguna funciona, alarma activa *)
        bomba1   := FALSE;
        bomba2   := FALSE;
        almFalla := TRUE;
    END_IF;

END_IF;

END_FUNCTION_BLOCK