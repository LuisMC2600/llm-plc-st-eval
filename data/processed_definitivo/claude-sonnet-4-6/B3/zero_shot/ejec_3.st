FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Señal del sensor fotoeléctrico *)
    btnReset    : BOOL; (* Botón de reset de la cuenta *)
END_VAR

VAR_OUTPUT
    loteListo : BOOL; (* Activa cuando se completan 12 piezas *)
    cuenta    : INT;  (* Contador de piezas detectadas *)
END_VAR

VAR
    sensorPiezaPrev : BOOL; (* Estado anterior del sensor para detección de flanco *)
END_VAR

VAR CONSTANT
    LIMITE_LOTE : INT := 12; (* Número de piezas por lote *)
END_VAR

(* ─────────────────────────────────────────────
   Lógica principal del contador de piezas
   ───────────────────────────────────────────── *)

(* 1. Reset: tiene prioridad sobre el conteo *)
IF btnReset THEN
    cuenta    := 0;
    loteListo := FALSE;

(* 2. Conteo: detecta flanco ascendente del sensor (FALSE → TRUE) *)
ELSIF (sensorPieza = TRUE) AND (sensorPiezaPrev = FALSE) THEN

    (* Incrementar solo si el lote aún no está completo *)
    IF cuenta < LIMITE_LOTE THEN
        cuenta := cuenta + 1;
    END_IF;

    (* Activar salida de lote al alcanzar el límite *)
    IF cuenta >= LIMITE_LOTE THEN
        loteListo := TRUE;
    END_IF;

END_IF;

(* 3. Guardar estado actual del sensor para el próximo ciclo *)
sensorPiezaPrev := sensorPieza;