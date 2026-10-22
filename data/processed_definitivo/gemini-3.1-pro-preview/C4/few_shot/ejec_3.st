FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Señal de peticion de arranque del sistema *)
    falla1 : BOOL;  (* Señal de falla de la bomba 1 *)
    falla2 : BOOL;  (* Señal de falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   (* Comando de arranque para la bomba 1 *)
    bomba2 : BOOL;   (* Comando de arranque para la bomba 2 *)
    almFalla : BOOL; (* Alarma indicadora de falla en la bomba titular *)
END_VAR
VAR
    turno : BOOL;    (* Bandera de alternancia (TRUE = Bomba 1 titular, FALSE = Bomba 2 titular) *)
    fDem : R_TRIG;   (* Detector de flanco de subida para la señal de demanda *)
END_VAR

(* Detecta el instante en que inicia una nueva demanda *)
fDem(CLK := demanda);

(* Alterna el turno de las bombas en cada nuevo arranque para igualar el desgaste *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* Logica de operacion mientras exista demanda *)
IF demanda THEN
    IF turno THEN
        (* --- Turno de la Bomba 1 como titular --- *)
        bomba1 := NOT falla1;                   (* La bomba 1 opera si no tiene falla *)
        bomba2 := falla1 AND NOT falla2;        (* La bomba 2 entra al relevo si la 1 falla y la 2 esta sana *)
        almFalla := falla1;                     (* Se activa la alarma si la bomba titular (1) falla *)
    ELSE
        (* --- Turno de la Bomba 2 como titular --- *)
        bomba2 := NOT falla2;                   (* La bomba 2 opera si no tiene falla *)
        bomba1 := falla2 AND NOT falla1;        (* La bomba 1 entra al relevo si la 2 falla y la 1 esta sana *)
        almFalla := falla2;                     (* Se activa la alarma si la bomba titular (2) falla *)
    END_IF
ELSE
    (* Si no hay demanda, se apagan todos los equipos y la alarma *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK