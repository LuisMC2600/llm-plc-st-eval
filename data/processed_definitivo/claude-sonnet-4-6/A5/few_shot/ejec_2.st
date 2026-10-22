TYPE
    ST_Evento : STRUCT
        codigo : INT;  (* Código del evento *)
        marca  : TIME; (* Marca de tiempo acumulado *)
    END_STRUCT;
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento     : INT;  (* Código del evento a registrar *)
    nuevoEvento: BOOL; (* Flanco ascendente dispara el registro *)
    ciclo      : TIME; (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    buffer   : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice   : INT;                        (* Posición del último evento registrado; -1 si ninguno *)
    nEventos : INT;                        (* Cantidad de posiciones válidas en el buffer (0-20) *)
END_VAR
VAR
    tAcumulado    : TIME; (* Tiempo acumulado desde el arranque *)
    prevNuevoEvento: BOOL; (* Valor anterior de nuevoEvento para detección de flanco *)
    nextIndice    : INT;  (* Próxima posición de escritura en el buffer *)
END_VAR

(* Acumular tiempo de ciclo en cada ejecución *)
tAcumulado := tAcumulado + ciclo;

(* Detectar flanco ascendente de nuevoEvento *)
IF nuevoEvento AND NOT prevNuevoEvento THEN

    (* Escribir en la posición nextIndice del buffer circular *)
    buffer[nextIndice].codigo := evento;
    buffer[nextIndice].marca  := tAcumulado;

    (* Actualizar índice del último evento registrado *)
    indice := nextIndice;

    (* Avanzar el puntero de escritura de forma circular *)
    nextIndice := (nextIndice + 1) MOD 20;

    (* Incrementar contador de eventos válidos hasta el máximo *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;

END_IF;

(* Actualizar valor previo para la próxima ejecución *)
prevNuevoEvento := nuevoEvento;

END_FUNCTION_BLOCK