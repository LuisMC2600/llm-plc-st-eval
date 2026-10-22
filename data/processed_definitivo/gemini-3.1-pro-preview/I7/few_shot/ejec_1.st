FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Senal de arranque del grupo *)
    falla1 : BOOL;  (* Falla de la bomba 1 *)
    falla2 : BOOL;  (* Falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   (* Comando de la bomba 1 *)
    bomba2 : BOOL;   (* Comando de la bomba 2 *)
    almFalla : BOOL; (* Alarma de falla en bomba principal *)
END_VAR
VAR
    rTrigDemanda : R_TRIG; (* Detector de flanco de subida de la demanda *)
    turnoBomba2 : BOOL := TRUE; (* Inicia en TRUE para que la primera demanda asigne el turno a la bomba 1 *)
END_VAR

(* Deteccion de nueva demanda para alternar el turno *)
rTrigDemanda(CLK := demanda);
IF rTrigDemanda.Q THEN
    turnoBomba2 := NOT turnoBomba2;
END_IF;

(* Logica de control de bombas y alarmas *)
IF demanda THEN
    IF NOT turnoBomba2 THEN
        (* Bomba 1 es la principal *)
        bomba1 := NOT falla1;
        bomba2 := falla1 AND NOT falla2;
        almFalla := falla1;
    ELSE
        (* Bomba 2 es la principal *)
        bomba2 := NOT falla2;
        bomba1 := falla2 AND NOT falla1;
        almFalla := falla2;
    END_IF;
ELSE
    (* Sin demanda, ambas bombas y la alarma se apagan *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF;
END_FUNCTION_BLOCK