FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Señal del sensor fotoeléctrico *)
    btnReset    : BOOL; (* Botón de reset de cuenta y lote *)
END_VAR

VAR_OUTPUT
    loteListo : BOOL; (* TRUE cuando se alcanzan 12 piezas *)
    cuenta    : INT;  (* Número de piezas contadas *)
END_VAR

VAR
    sensorPiezaAnterior : BOOL; (* Estado previo del sensor para detección de flanco *)
END_VAR

(* ─────────────────────────────────────────────
   Lógica principal
   ───────────────────────────────────────────── *)

(* 1. Reset: tiene prioridad sobre el conteo *)
IF btnReset THEN
    cuenta    := 0;
    loteListo := FALSE;

ELSE
    (* 2. Detección de flanco ascendente del sensor (FALSE → TRUE) *)
    IF sensorPieza AND NOT sensorPiezaAnterior THEN
        cuenta := cuenta + 1;
    END_IF;

    (* 3. Activar salida de lote al alcanzar 12 piezas *)
    IF cuenta >= 12 THEN
        loteListo := TRUE;
    END_IF;

END_IF;

(* 4. Guardar estado actual del sensor para el siguiente ciclo *)
sensorPiezaAnterior := sensorPieza;