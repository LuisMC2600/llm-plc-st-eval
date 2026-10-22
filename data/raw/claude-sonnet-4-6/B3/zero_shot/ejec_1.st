```pascal
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

(* ─────────────────────────────────────────────
   Constantes
   ───────────────────────────────────────────── *)
VAR CONSTANT
    TAMANO_LOTE : INT := 12; (* Piezas por lote *)
END_VAR

(* ══════════════════════════════════════════════
   LÓGICA PRINCIPAL
   ══════════════════════════════════════════════ *)

(* 1. Reset: tiene prioridad sobre el conteo *)
IF btnReset THEN
    cuenta        := 0;
    loteListo     := FALSE;
    sensorPiezaPrev := FALSE;

(* 2. Conteo normal: solo si el lote no está completo *)
ELSIF NOT loteListo THEN

    (* Detectar flanco ascendente del sensor (FALSE → TRUE) *)
    IF sensorPieza AND NOT sensorPiezaPrev THEN
        cuenta := cuenta + 1;
    END_IF;

    (* Activar salida cuando se alcanza el tamaño de lote *)
    IF cuenta >= TAMANO_LOTE THEN
        loteListo := TRUE;
    END_IF;

END_IF;

(* 3. Guardar estado actual del sensor para el próximo ciclo *)
sensorPiezaPrev := sensorPieza;
```