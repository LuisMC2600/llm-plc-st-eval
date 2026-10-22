FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoeléctrico para detectar piezas *)
    btnReset : BOOL;    (* Botón para resetear el contador *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL;   (* Indica si el lote está completo *)
    cuenta : INT;       (* Cuenta de piezas detectadas *)
END_VAR
VAR
    sensorPiezaAnt : BOOL; (* Estado anterior del sensor de pieza *)
END_VAR

(* Inicialización de variables *)
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
ELSE
    (* Detectar flanco ascendente del sensor de pieza *)
    IF (sensorPieza AND NOT sensorPiezaAnt) THEN
        cuenta := cuenta + 1;
    END_IF;

    (* Verificar si el lote está completo *)
    IF cuenta >= 12 THEN
        loteListo := TRUE;
    ELSE
        loteListo := FALSE;
    END_IF;
END_IF;

(* Actualizar el estado anterior del sensor de pieza *)
sensorPiezaAnt := sensorPieza;

END_FUNCTION_BLOCK