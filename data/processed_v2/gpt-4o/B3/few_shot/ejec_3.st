FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoeléctrico para detección de piezas *)
    btnReset : BOOL;    (* Botón para resetear el contador *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL;   (* Indica si el lote está completo *)
    cuenta : INT;       (* Contador de piezas *)
END_VAR
VAR
    sensorPiezaAnt : BOOL; (* Estado anterior del sensor de pieza *)
END_VAR

(* Detectar flanco ascendente del sensor de pieza *)
IF NOT sensorPiezaAnt AND sensorPieza THEN
    cuenta := cuenta + 1; (* Incrementar cuenta en flanco ascendente *)
END_IF

(* Resetear el contador y la salida de lote completo *)
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
END_IF

(* Verificar si el lote está completo *)
IF cuenta >= 12 THEN
    loteListo := TRUE;
ELSE
    loteListo := FALSE;
END_IF

(* Actualizar el estado anterior del sensor de pieza *)
sensorPiezaAnt := sensorPieza;

END_FUNCTION_BLOCK