```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha *)
    btnParo : BOOL;   (* Botón de paro *)
    btnEmerg : BOOL;  (* Botón de paro de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL;   (* Estado del motor *)
END_VAR
VAR
    estadoEmergencia : BOOL; (* Indica si hubo un paro de emergencia *)
END_VAR

(* Si se presiona el botón de emergencia, se activa el estado de emergencia *)
IF btnEmerg THEN
    estadoEmergencia := TRUE;
END_IF

(* Si no hay estado de emergencia, el motor se enciende con el botón de marcha y se apaga con el botón de paro *)
IF NOT estadoEmergencia THEN
    IF btnMarcha THEN
        motorOn := TRUE;
    END_IF;
    IF btnParo THEN
        motorOn := FALSE;
    END_IF;
ELSE
    (* Si hay estado de emergencia, el motor se apaga y no puede rearrancar *)
    motorOn := FALSE;
END_IF;
END_FUNCTION_BLOCK
```