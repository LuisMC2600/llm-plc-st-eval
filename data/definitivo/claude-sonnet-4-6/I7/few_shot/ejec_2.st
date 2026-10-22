```pascal
FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Señal de demanda de bombeo *)
    falla1  : BOOL; (* Falla de bomba 1 *)
    falla2  : BOOL; (* Falla de bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; (* Salida de bomba 1 *)
    bomba2   : BOOL; (* Salida de bomba 2 *)
    almFalla : BOOL; (* Alarma de falla en bomba principal *)
END_VAR
VAR
    principal1   : BOOL := TRUE;  (* TRUE = bomba1 es principal, FALSE = bomba2 es principal *)
    demandaAntes : BOOL := FALSE; (* Valor de demanda en el ciclo anterior, para detectar flanco *)
    flancoSubida : BOOL;          (* Flanco de subida de demanda *)
END_VAR

(* Detectar flanco de subida de demanda *)
flancoSubida := demanda AND NOT demandaAntes;

(* En cada flanco de subida se alterna la bomba principal *)
IF flancoSubida THEN
    principal1 := NOT principal1;
END_IF;

(* Lógica de control con demanda activa *)
IF demanda THEN
    IF principal1 THEN
        (* Bomba 1 es la principal *)
        IF NOT falla1 THEN
            (* Principal sin falla: funciona bomba 1 *)
            bomba1   := TRUE;
            bomba2   := FALSE;
            almFalla := FALSE;
        ELSIF NOT falla2 THEN
            (* Principal con falla, respaldo sin falla: funciona bomba 2 *)
            bomba1   := FALSE;
            bomba2   := TRUE;
            almFalla := TRUE;
        ELSE
            (* Ambas con falla: ninguna funciona *)
            bomba1   := FALSE;
            bomba2   := FALSE;
            almFalla := TRUE;
        END_IF;
    ELSE
        (* Bomba 2 es la principal *)
        IF NOT falla2 THEN
            (* Principal sin falla: funciona bomba 2 *)
            bomba1   := FALSE;
            bomba2   := TRUE;
            almFalla := FALSE;
        ELSIF NOT falla1 THEN
            (* Principal con falla, respaldo sin falla: funciona bomba 1 *)
            bomba1   := TRUE;
            bomba2   := FALSE;
            almFalla := TRUE;
        ELSE
            (* Ambas con falla: ninguna funciona *)
            bomba1   := FALSE;
            bomba2   := FALSE;
            almFalla := TRUE;
        END_IF;
    END_IF;
ELSE
    (* Sin demanda: ambas bombas detenidas, sin alarma *)
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;
END_IF;

(* Guardar estado de demanda para el próximo ciclo *)
demandaAntes := demanda;

END_FUNCTION_BLOCK
```