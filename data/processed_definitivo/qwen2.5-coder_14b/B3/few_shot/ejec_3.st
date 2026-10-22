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

(* Almacenar el estado anterior del sensor *)
sensorAnterior := sensorPieza;

(* Incrementar la cuenta cuando el sensor detecta una pieza *)
IF sensorPieza AND NOT sensorAnterior THEN
    cuenta := cuenta + 1;
END_IF;

(* Resetear el contador y la salida de lote *)
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
END_IF;

(* Activar la salida de lote completo cuando se llega a 12 piezas *)
IF cuenta >= 12 THEN
    loteListo := TRUE;
END_IF;

END_FUNCTION_BLOCK