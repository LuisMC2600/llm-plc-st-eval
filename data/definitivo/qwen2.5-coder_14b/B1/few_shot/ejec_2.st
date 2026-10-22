FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Boton de marcha *)
    btnParo : BOOL; (* Boton de paro *)
    btnEmerg : BOOL; (* Boton de emergencia *)
END_VAR
VAR_OUTPUT
    motorOn : BOOL; (* Estado del motor *)
END_VAR
VAR
    estadoEmergencia : BOOL; (* Estado de emergencia *)
END_VAR

(* Manejo del estado de emergencia *)
estadoEmergencia := estadoEmergencia OR btnEmerg;

(* Control del motor *)
IF estadoEmergencia THEN
    motorOn := FALSE; (* El motor se detiene en caso de emergencia *)
ELSE
    IF btnParo THEN
        motorOn := FALSE; (* El motor se detiene al pulsar el botón de paro *)
    ELSE
        motorOn := motorOn OR btnMarcha; (* El motor se mantiene encendido al soltar el botón de marcha *)
    END_IF
END_IF;

END_FUNCTION_BLOCK