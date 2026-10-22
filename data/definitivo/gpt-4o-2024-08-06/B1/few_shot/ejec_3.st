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
    estadoMotor : BOOL; (* Estado interno del motor *)
END_VAR

(* Control de arranque y paro del motor *)
IF btnEmerg THEN
    estadoMotor := FALSE; (* Paro de emergencia, motor apagado *)
ELSIF btnParo THEN
    estadoMotor := FALSE; (* Botón de paro, motor apagado *)
ELSIF btnMarcha THEN
    estadoMotor := TRUE;  (* Botón de marcha, motor encendido *)
END_IF

motorOn := estadoMotor; (* Salida del estado del motor *)
END_FUNCTION_BLOCK
```