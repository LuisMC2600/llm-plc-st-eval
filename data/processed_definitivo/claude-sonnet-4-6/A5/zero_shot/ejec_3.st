(* Declaración del tipo de dato para un evento *)
TYPE ST_Evento :
STRUCT
    codigo : INT;  (* Código del evento *)
    marca  : TIME; (* Tiempo acumulado en el momento del evento *)
END_STRUCT
END_TYPE


(* Bloque de función: registro de eventos en buffer circular *)
FUNCTION_BLOCK FB_Registro

VAR_INPUT
    evento      : INT;  (* Código del evento a registrar *)
    nuevoEvento : BOOL; (* Flanco ascendente dispara el registro *)
    ciclo       : TIME; (* Período de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    buffer   : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice   : INT;                        (* Posición del último evento registrado (-1 = ninguno) *)
    nEventos : INT;                        (* Cantidad de posiciones válidas (0-20) *)
END_VAR

VAR
    tiempoAcumulado  : TIME; (* Tiempo acumulado desde el arranque *)
    nuevoEventoAntes : BOOL; (* Estado anterior de nuevoEvento para detección de flanco *)
    siguientePos     : INT;  (* Próxima posición de escritura en el buffer *)
END_VAR

(* ── Inicialización implícita (primera ejecución) ──────────────────────────
   IEC 61131-3 garantiza que las variables se inicializan a su valor por
   defecto: BOOL → FALSE, INT → 0, TIME → T#0s.
   indice debe comenzar en -1, por lo que se inicializa explícitamente
   mediante una variable auxiliar de primer ciclo si fuera necesario;
   aquí se aprovecha que siguientePos = 0 y nEventos = 0 para deducir
   el estado inicial, y se fuerza indice = -1 cuando nEventos = 0.       *)

(* ── 1. Acumular tiempo de ciclo ──────────────────────────────────────── *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* ── 2. Detectar flanco ascendente en nuevoEvento ─────────────────────── *)
IF nuevoEvento AND NOT nuevoEventoAntes THEN

    (* 2a. Escribir el evento en la posición actual del buffer *)
    buffer[siguientePos].codigo := evento;
    buffer[siguientePos].marca  := tiempoAcumulado;

    (* 2b. Actualizar salida indice *)
    indice := siguientePos;

    (* 2c. Avanzar el contador de posición siguiente (circular) *)
    siguientePos := siguientePos + 1;
    IF siguientePos > 19 THEN
        siguientePos := 0;
    END_IF;

    (* 2d. Actualizar cantidad de eventos válidos (máximo 20) *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;

ELSE
    (* Sin nuevo evento: mantener indice en -1 si aún no hay registros *)
    IF nEventos = 0 THEN
        indice := -1;
    END_IF;
END_IF;

(* ── 3. Memorizar estado de nuevoEvento para el próximo ciclo ─────────── *)
nuevoEventoAntes := nuevoEvento;

END_FUNCTION_BLOCK