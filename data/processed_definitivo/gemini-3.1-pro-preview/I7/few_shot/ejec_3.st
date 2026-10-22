FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Peticion de arranque *)
    falla1 : BOOL;  (* Falla de la bomba 1 *)
    falla2 : BOOL;  (* Falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   (* Comando de arranque bomba 1 *)
    bomba2 : BOOL;   (* Comando de arranque bomba 2 *)
    almFalla : BOOL; (* Alarma de falla en la bomba principal *)
END_VAR
VAR
    flancoDemanda : R_TRIG; (* Detector de flanco de subida *)
    bomba1Principal : BOOL := FALSE; (* Alternancia: inicia en FALSE para que el primer pulso lo haga TRUE *)
END_VAR

(* Deteccion de nueva demanda para alternar el rol de bomba principal *)
flancoDemanda(CLK := demanda);
IF flancoDemanda.Q THEN
    bomba1Principal := NOT bomba1Principal;
END_IF;

(* La bomba 1 arranca si hay demanda, no tiene falla, y es la principal o la bomba 2 (principal) fallo *)
bomba1 := demanda AND NOT falla1 AND (bomba1Principal OR falla2);

(* La bomba 2 arranca si hay demanda, no tiene falla, y es la principal o la bomba 1 (principal) fallo *)
bomba2 := demanda AND NOT falla2 AND (NOT bomba1Principal OR falla1);

(* La alarma se activa solo si hay demanda y la bomba que tiene el rol principal presenta falla *)
almFalla := demanda AND ((bomba1Principal AND falla1) OR (NOT bomba1Principal AND falla2));
END_FUNCTION_BLOCK