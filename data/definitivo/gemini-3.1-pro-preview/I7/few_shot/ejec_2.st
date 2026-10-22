FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Señal de demanda de bombeo *)
    falla1  : BOOL; (* Falla de la bomba 1 *)
    falla2  : BOOL; (* Falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; (* Comando de arranque bomba 1 *)
    bomba2   : BOOL; (* Comando de arranque bomba 2 *)
    almFalla : BOOL; (* Alarma de falla en bomba principal *)
END_VAR
VAR
    rTrigDemanda : R_TRIG; (* Detector de flanco de subida de la demanda *)
    turnoBomba1  : BOOL := FALSE; (* Alternancia, inicia en FALSE para que el primer cambio sea a TRUE *)
END_VAR

(* Alternar la bomba principal en cada nueva demanda (transicion de FALSE a TRUE) *)
rTrigDemanda(CLK := demanda);
IF rTrigDemanda.Q THEN
    turnoBomba1 := NOT turnoBomba1;
END_IF;

(* Control de bombas y alarma segun la demanda y el turno *)
IF demanda THEN
    IF turnoBomba1 THEN
        (* Bomba 1 es principal, Bomba 2 es respaldo *)
        bomba1 := NOT falla1;
        bomba2 := falla1 AND NOT falla2;
        almFalla := falla1;
    ELSE
        (* Bomba 2 es principal, Bomba 1 es respaldo *)
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