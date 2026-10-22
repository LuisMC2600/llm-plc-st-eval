FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoeléctrico para detección de piezas *)
    btnReset : BOOL;    (* Botón para reiniciar el contador *)
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
    (* Detecta la transición de FALSE a TRUE del sensor de pieza *)
    IF (sensorPieza AND NOT sensorPiezaAnt) THEN
        cuenta := cuenta + 1;
    END_IF;

    (* Verifica si se ha alcanzado el conteo de 12 piezas *)
    IF cuenta >= 12 THEN
        loteListo := TRUE;
    ELSE
        loteListo := FALSE;
    END_IF;
END_IF;

(* Actualiza el estado anterior del sensor de pieza *)
sensorPiezaAnt := sensorPieza;
END_FUNCTION_BLOCK