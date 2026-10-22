FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoeléctrico de pieza *)
    btnReset : BOOL; (* Botón de reset *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Salida de lote completo *)
    cuenta : INT; (* Contador de piezas *)
END_VAR
VAR
    sensorAnterior : BOOL; (* Estado anterior del sensor *)
END_VAR

(* Reinicio del contador *)
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
END_IF

(* Detección de transición del sensor *)
IF sensorPieza AND NOT sensorAnterior THEN
    cuenta := cuenta + 1;
END_IF

(* Actualización del estado del sensor *)
sensorAnterior := sensorPieza;

(* Control de la salida de lote completo *)
IF cuenta >= 12 THEN
    loteListo := TRUE;
ELSE
    loteListo := FALSE;
END_IF
END_FUNCTION_BLOCK