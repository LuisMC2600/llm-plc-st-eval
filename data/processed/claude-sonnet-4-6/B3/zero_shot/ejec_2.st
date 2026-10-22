FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Señal del sensor fotoeléctrico *)
    btnReset    : BOOL; (* Botón de reset de cuenta y lote *)
END_VAR

VAR_OUTPUT
    loteListo : BOOL; (* Activa cuando se completan 12 piezas *)
    cuenta    : INT;  (* Número de piezas contadas *)
END_VAR

VAR
    sensorPiezaAnterior : BOOL; (* Valor previo del sensor para detectar flanco *)
END_VAR

(* ── Constantes ── *)
VAR CONSTANT
    TAMANO_LOTE : INT := 12; (* Número de piezas por lote *)
END_VAR

(* ════════════════════════════════════════════════════════
   Lógica principal
   ════════════════════════════════════════════════════════ *)

(* 1. Reset: prioridad alta sobre el conteo *)
IF btnReset THEN
    cuenta    := 0;
    loteListo := FALSE;

ELSE
    (* 2. Detección de flanco ascendente del sensor (FALSE → TRUE) *)
    IF sensorPieza AND NOT sensorPiezaAnterior THEN
        (* Solo contar si el lote aún no está completo *)
        IF NOT loteListo THEN
            cuenta := cuenta + 1;
        END_IF;
    END_IF;

    (* 3. Activar salida de lote al alcanzar el tamaño definido *)
    IF cuenta >= TAMANO_LOTE THEN
        loteListo := TRUE;
    END_IF;
END_IF;

(* 4. Actualizar memoria de flanco para el próximo ciclo *)
sensorPiezaAnterior := sensorPieza;