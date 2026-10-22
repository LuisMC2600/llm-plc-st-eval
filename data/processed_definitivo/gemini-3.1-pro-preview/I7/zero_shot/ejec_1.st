FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Señal de petición de funcionamiento *)
    falla1  : BOOL; (* Señal de falla de la bomba 1 *)
    falla2  : BOOL; (* Señal de falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; (* Comando de marcha para la bomba 1 *)
    bomba2   : BOOL; (* Comando de marcha para la bomba 2 *)
    almFalla : BOOL; (* Alarma activa si la bomba principal falla durante la demanda *)
END_VAR
VAR
    demandaAnt     : BOOL := FALSE; (* Memoria del estado anterior de la demanda *)
    turnoBomba1    : BOOL := TRUE;  (* TRUE = Bomba 1 principal, FALSE = Bomba 2 principal *)
    primerArranque : BOOL := TRUE;  (* Bandera para forzar bomba 1 en la primera demanda *)
END_VAR

(* Detección de flanco de subida en la demanda para alternar el turno *)
IF demanda AND NOT demandaAnt THEN
    IF primerArranque THEN
        turnoBomba1 := TRUE;
        primerArranque := FALSE;
    ELSE
        turnoBomba1 := NOT turnoBomba1;
    END_IF;
END_IF;
demandaAnt := demanda;

(* Inicialización de salidas (estado de reposo) *)
bomba1   := FALSE;
bomba2   := FALSE;
almFalla := FALSE;

(* Lógica de operación cuando hay demanda activa *)
IF demanda THEN
    IF turnoBomba1 THEN
        (* Turno: Bomba 1 es la principal *)
        IF NOT falla1 THEN
            bomba1 := TRUE;
        ELSE
            almFalla := TRUE; (* Falla la principal, se activa alarma *)
            IF NOT falla2 THEN
                bomba2 := TRUE; (* Entra la bomba 2 de respaldo *)
            END_IF;
        END_IF;
    ELSE
        (* Turno: Bomba 2 es la principal *)
        IF NOT falla2 THEN
            bomba2 := TRUE;
        ELSE
            almFalla := TRUE; (* Falla la principal, se activa alarma *)
            IF NOT falla1 THEN
                bomba1 := TRUE; (* Entra la bomba 1 de respaldo *)
            END_IF;
        END_IF;
    END_IF;
END_IF;

END_FUNCTION_BLOCK