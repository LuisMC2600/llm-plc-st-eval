FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Indica si hay una demanda de activación *)
    falla1 : BOOL; (* Indica si la bomba1 está fallando *)
    falla2 : BOOL; (* Indica si la bomba2 está fallando *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL; (* Control de la bomba1 *)
    bomba2 : BOOL; (* Control de la bomba2 *)
    almFalla : BOOL; (* Almacena la última falla detectada *)
END_VAR
VAR
    turno : BOOL; (* Variable de control para alternar entre bomba1 y bomba2 *)
    fDem : R_TRIG; (* Flanco de subida de la demanda *)
END_VAR

(* Detecta el flanco de subida de la demanda *)
fDem(CLK := demanda);
IF fDem.Q THEN
    (* Alterna el turno entre bomba1 y bomba2 *)
    turno := NOT turno;
END_IF

(* Si hay una demanda *)
IF demanda THEN
    (* Si el turno está en bomba1 *)
    IF turno THEN
        (* Activa bomba1 si no está fallando *)
        bomba1 := NOT falla1;
        (* Activa bomba2 si está fallando bomba1 y no está fallando bomba2 *)
        bomba2 := falla1 AND NOT falla2;
        (* Almacena la última falla detectada *)
        almFalla := falla1;
    ELSE
        (* Si el turno está en bomba2 *)
        (* Activa bomba2 si no está fallando *)
        bomba2 := NOT falla2;
        (* Activa bomba1 si está fallando bomba2 y no está fallando bomba1 *)
        bomba1 := falla2 AND NOT falla1;
        (* Almacena la última falla detectada *)
        almFalla := falla2;
    END_IF
ELSE
    (* Si no hay demanda, apaga ambas bombas *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    (* Limpia el registro de la última falla *)
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK