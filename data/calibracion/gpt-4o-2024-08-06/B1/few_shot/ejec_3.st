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
    motorActivo : BOOL; (* Estado interno del motor *)
END_VAR

(* Lógica de control del motor *)
IF btnEmerg THEN
    motorActivo := FALSE; (* Paro de emergencia desactiva el motor *)
ELSIF btnParo THEN
    motorActivo := FALSE; (* Botón de paro desactiva el motor *)
ELSIF btnMarcha THEN
    motorActivo := TRUE;  (* Botón de marcha activa el motor *)
END_IF

motorOn := motorActivo; (* Salida del estado del motor *)
END_FUNCTION_BLOCK
```