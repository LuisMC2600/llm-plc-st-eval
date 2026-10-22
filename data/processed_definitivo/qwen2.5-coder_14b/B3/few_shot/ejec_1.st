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

(* Reseteo del contador y la salida de lote *)
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
ELSE
    (* Incremento del contador *)
    IF sensorPieza AND NOT sensorAnterior THEN
        cuenta := cuenta + 1;
    END_IF

    (* Activación de la salida de lote completo *)
    IF cuenta >= 12 THEN
        loteListo := TRUE;
    END_IF
END_IF

(* Actualización del estado anterior del sensor *)
sensorAnterior := sensorPieza;
END_FUNCTION_BLOCK