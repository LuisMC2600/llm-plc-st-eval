(* Declaración del tipo de dato para un evento *)
TYPE
    ST_Evento :
    STRUCT
        codigo : INT;  (* Código del evento *)
        marca  : TIME; (* Tiempo acumulado en el momento del evento *)
    END_STRUCT
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
    nEventos : INT;                        (* Cantidad de posiciones válidas (0..20) *)
END_VAR

VAR
    tiempoAcumulado  : TIME; (* Tiempo acumulado desde el arranque *)
    nuevoEventoPrev  : BOOL; (* Valor de nuevoEvento en el ciclo anterior *)
    siguientePosicion: INT;  (* Próxima posición de escritura en el buffer *)
END_VAR

(* ── Inicialización implícita en primer ciclo ─────────────────────────────
   IEC 61131-3 garantiza que las variables se inicializan a su valor por
   defecto (0 / FALSE / T#0s) antes de la primera ejecución.
   indice se inicializa explícitamente a -1 en la lógica de arranque.     *)

(* Acumular tiempo de ejecución *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detectar flanco ascendente de nuevoEvento *)
IF nuevoEvento AND NOT nuevoEventoPrev THEN

    (* Calcular la posición de escritura en el buffer circular *)
    siguientePosicion := (indice + 1) MOD 20;
    (* Nota: cuando indice = -1, (-1 + 1) MOD 20 = 0, posición correcta *)

    (* Registrar el evento *)
    buffer[siguientePosicion].codigo := evento;
    buffer[siguientePosicion].marca  := tiempoAcumulado;

    (* Actualizar índice al último evento registrado *)
    indice := siguientePosicion;

    (* Actualizar contador de eventos válidos (máximo 20) *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;

END_IF;

(* Guardar estado de nuevoEvento para detección de flanco en el próximo ciclo *)
nuevoEventoPrev := nuevoEvento;