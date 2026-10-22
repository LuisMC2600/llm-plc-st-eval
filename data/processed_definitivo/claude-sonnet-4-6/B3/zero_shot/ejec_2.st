FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Señal del sensor fotoeléctrico *)
    btnReset    : BOOL; (* Botón de reset de la cuenta *)
END_VAR

VAR_OUTPUT
    loteListo : BOOL; (* Activa cuando se completan 12 piezas *)
    cuenta    : INT;  (* Número de piezas contadas *)
END_VAR

VAR
    sensorPiezaPrev : BOOL; (* Estado anterior del sensor para detección de flanco *)
END_VAR

(*
    Constante de tamaño de lote.
    Ajustar según requerimiento de producción.
*)
VAR CONSTANT
    TAMANO_LOTE : INT := 12;
END_VAR

(* ─────────────────────────────────────────────
   LÓGICA PRINCIPAL
   ───────────────────────────────────────────── *)

(* 1. Reset: tiene prioridad sobre el conteo *)
IF btnReset THEN
    cuenta        := 0;
    loteListo     := FALSE;
    sensorPiezaPrev := FALSE;

ELSE
    (* 2. Detección de flanco ascendente del sensor (FALSE → TRUE) *)
    IF sensorPieza AND NOT sensorPiezaPrev THEN
        (* Incrementar solo si el lote aún no está completo *)
        IF cuenta < TAMANO_LOTE THEN
            cuenta := cuenta + 1;
        END_IF;
    END_IF;

    (* 3. Activar salida de lote completo *)
    IF cuenta >= TAMANO_LOTE THEN
        loteListo := TRUE;
    END_IF;

END_IF;

(* 4. Guardar estado actual del sensor para el siguiente ciclo *)
sensorPiezaPrev := sensorPieza;

END_FUNCTION_BLOCK