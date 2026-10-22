```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoeléctrico para detección de piezas *)
    btnReset : BOOL;    (* Botón para resetear el contador *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL;   (* Indica si el lote está completo *)
    cuenta : INT;       (* Cuenta de piezas detectadas *)
END_VAR
VAR
    sensorPiezaAnt : BOOL; (* Estado anterior del sensor de pieza *)
END_VAR

(* Inicialización del estado anterior del sensor *)
IF btnReset THEN
    cuenta := 0;        (* Resetear la cuenta a cero *)
    loteListo := FALSE; (* Desactivar la salida de lote completo *)
ELSE
    (* Detectar transición de FALSE a TRUE en el sensor de pieza *)
    IF NOT sensorPiezaAnt AND sensorPieza THEN
        cuenta := cuenta + 1; (* Incrementar la cuenta *)
    END_IF;
    
    (* Verificar si se ha alcanzado el conteo de 12 piezas *)
    IF cuenta >= 12 THEN
        loteListo := TRUE; (* Activar la salida de lote completo *)
    ELSE
        loteListo := FALSE; (* Desactivar la salida de lote completo *)
    END_IF;
END_IF;

(* Actualizar el estado anterior del sensor *)
sensorPiezaAnt := sensorPieza;
END_FUNCTION_BLOCK
```