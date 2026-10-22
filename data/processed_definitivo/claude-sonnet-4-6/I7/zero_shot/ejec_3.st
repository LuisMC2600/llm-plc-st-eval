FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Señal de demanda de operación *)
    falla1  : BOOL; (* Falla activa de bomba 1 *)
    falla2  : BOOL; (* Falla activa de bomba 2 *)
END_VAR

VAR_OUTPUT
    bomba1  : BOOL; (* Comando de arranque bomba 1 *)
    bomba2  : BOOL; (* Comando de arranque bomba 2 *)
    almFalla : BOOL; (* Alarma: falla en bomba principal con demanda activa *)
END_VAR

VAR
    demanda_prev  : BOOL; (* Valor de demanda en el ciclo anterior, para detectar flanco *)
    principal_es1 : BOOL := TRUE; (* TRUE = bomba1 es principal en el ciclo actual *)
END_VAR

(* ── Detección de flanco ascendente de demanda ─────────────────────────── *)
(* En cada transición FALSE→TRUE se alterna el rol de principal            *)
IF demanda AND NOT demanda_prev THEN
    principal_es1 := NOT principal_es1; (* Alternar principal en nueva demanda *)
END_IF;

(* ── Lógica de arranque y alarma ────────────────────────────────────────── *)
(* Inicializar salidas *)
bomba1   := FALSE;
bomba2   := FALSE;
almFalla := FALSE;

IF demanda THEN
    IF principal_es1 THEN
        (* Bomba 1 es la principal *)
        IF NOT falla1 THEN
            (* Principal sana: arranca bomba 1 *)
            bomba1 := TRUE;
        ELSE
            (* Principal con falla: activar alarma *)
            almFalla := TRUE;
            IF NOT falla2 THEN
                (* Respaldo sano: arranca bomba 2 *)
                bomba2 := TRUE;
            END_IF;
            (* Si falla2 también activa: ninguna bomba arranca, almFalla ya activo *)
        END_IF;
    ELSE
        (* Bomba 2 es la principal *)
        IF NOT falla2 THEN
            (* Principal sana: arranca bomba 2 *)
            bomba2 := TRUE;
        ELSE
            (* Principal con falla: activar alarma *)
            almFalla := TRUE;
            IF NOT falla1 THEN
                (* Respaldo sano: arranca bomba 1 *)
                bomba1 := TRUE;
            END_IF;
            (* Si falla1 también activa: ninguna bomba arranca, almFalla ya activo *)
        END_IF;
    END_IF;
END_IF;
(* Si demanda = FALSE: bomba1, bomba2 y almFalla permanecen FALSE (ambas detenidas) *)

(* ── Actualizar memoria de demanda para el próximo ciclo ────────────────── *)
demanda_prev := demanda;