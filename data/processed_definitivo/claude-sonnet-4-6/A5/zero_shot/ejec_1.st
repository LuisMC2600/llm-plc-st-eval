(* Declaración del tipo de dato para un evento *)
TYPE
    ST_Evento :
    STRUCT
        codigo : INT;  (* Código del evento *)
        marca  : TIME; (* Tiempo acumulado en el momento del evento *)
    END_STRUCT;
END_TYPE


(* Bloque de función: registro de eventos en buffer circular *)
FUNCTION_BLOCK FB_Registro

VAR_INPUT
    evento      : INT;  (* Código del evento a registrar *)
    nuevoEvento : BOOL; (* Flanco ascendente activa el registro *)
    ciclo       : TIME; (* Período de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    buffer   : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice   : INT;                        (* Posición del último evento registrado; -1 si ninguno *)
    nEventos : INT;                        (* Cantidad de posiciones válidas en el buffer (0-20) *)
END_VAR

VAR
    tiempoAcumulado  : TIME; (* Tiempo acumulado desde el arranque del bloque *)
    nuevoEventoAntes : BOOL; (* Valor de nuevoEvento en el ciclo anterior, para detectar flanco *)
    nextPos          : INT;  (* Próxima posición de escritura en el buffer *)
END_VAR

(* ── Inicialización implícita (primera ejecución) ─────────────────────────
   IEC 61131-3 garantiza que las variables se inicializan a su valor por
   defecto: BOOL → FALSE, INT → 0, TIME → T#0s.
   indice se inicializa explícitamente a -1 en la declaración no es posible
   con valor negativo en todos los entornos, por lo que se gestiona aquí. *)

(* Acumular tiempo de ciclo *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detectar flanco ascendente en nuevoEvento *)
IF nuevoEvento AND NOT nuevoEventoAntes THEN

    (* Calcular la posición de escritura en el buffer circular *)
    (* nextPos ya apunta a la posición correcta (inicia en 0) *)

    (* Escribir el evento en el buffer *)
    buffer[nextPos].codigo := evento;
    buffer[nextPos].marca  := tiempoAcumulado;

    (* Actualizar la salida indice con la posición recién escrita *)
    indice := nextPos;

    (* Avanzar el contador de eventos válidos hasta el máximo (20) *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;

    (* Avanzar nextPos de forma circular *)
    nextPos := nextPos + 1;
    IF nextPos > 19 THEN
        nextPos := 0;
    END_IF;

END_IF;

(* Guardar estado de nuevoEvento para el próximo ciclo *)
nuevoEventoAntes := nuevoEvento;

(* Nota: indice vale 0 en el primer ciclo antes de cualquier evento.
   Para cumplir el requisito de -1 inicial se usa la siguiente lógica: *)
(* Se reescribe indice a -1 solo mientras no se haya registrado ningún evento *)
IF nEventos = 0 THEN
    indice := -1;
END_IF;

END_FUNCTION_BLOCK