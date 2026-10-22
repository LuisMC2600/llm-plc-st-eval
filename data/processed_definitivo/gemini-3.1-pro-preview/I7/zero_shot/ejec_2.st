FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Señal de demanda del sistema *)
    falla1  : BOOL; (* Señal de falla de la bomba 1 *)
    falla2  : BOOL; (* Señal de falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; (* Comando de marcha para la bomba 1 *)
    bomba2   : BOOL; (* Comando de marcha para la bomba 2 *)
    almFalla : BOOL; (* Alarma de falla de la bomba principal *)
END_VAR
VAR
    flancoDemanda   : R_TRIG; (* Detector de flanco de subida *)
    bomba1Principal : BOOL := FALSE; (* Inicia en FALSE para cambiar a TRUE en la 1ra demanda *)
END_VAR

(* Detectar transición de FALSE a TRUE en la demanda *)
flancoDemanda(CLK := demanda);

(* Alternar el rol de bomba principal en cada nueva demanda *)
IF flancoDemanda.Q THEN
    bomba1Principal := NOT bomba1Principal;
END_IF;

(* Lógica de control de bombas y alarma *)
IF demanda THEN
    IF bomba1Principal THEN
        (* Ciclo donde Bomba 1 es la principal *)
        bomba1   := NOT falla1;
        bomba2   := falla1 AND NOT falla2; (* Respaldo si la principal falla y respaldo está OK *)
        almFalla := falla1;                (* Alarma activa solo por falla de la principal *)
    ELSE
        (* Ciclo donde Bomba 2 es la principal *)
        bomba2   := NOT falla2;
        bomba1   := falla2 AND NOT falla1; (* Respaldo si la principal falla y respaldo está OK *)
        almFalla := falla2;                (* Alarma activa solo por falla de la principal *)
    END_IF;
ELSE
    (* Si no hay demanda, se detienen las bombas y se apaga la alarma *)
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;
END_IF;
END_FUNCTION_BLOCK