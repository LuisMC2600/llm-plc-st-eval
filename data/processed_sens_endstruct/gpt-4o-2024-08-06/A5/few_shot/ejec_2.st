TYPE
    ST_Evento : STRUCT
        codigo : INT;  (* Código del evento *)
        marca : TIME;  (* Marca de tiempo del evento *)
    END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT;      (* Código del evento entrante *)
    nuevoEvento : BOOL; (* Señal de nuevo evento *)
    ciclo : TIME;      (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice : INT;       (* Índice del último evento registrado *)
    nEventos : INT;     (* Número de eventos válidos en el buffer *)
END_VAR
VAR
    tiempoAcumulado : TIME := T#0S; (* Tiempo acumulado desde el arranque *)
    eventoPrevio : BOOL := FALSE;   (* Estado previo de nuevoEvento *)
    posicion : INT := 0;            (* Posición actual en el buffer *)
END_VAR

(* Acumula el tiempo de ejecución *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detecta el flanco de subida de nuevoEvento *)
IF (nuevoEvento AND NOT eventoPrevio) THEN
    (* Registra el nuevo evento en el buffer *)
    buffer[posicion].codigo := evento;
    buffer[posicion].marca := tiempoAcumulado;
    
    (* Actualiza el índice y el número de eventos *)
    indice := posicion;
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;
    
    (* Avanza la posición en el buffer, con retorno circular *)
    posicion := (posicion + 1) MOD 20;
END_IF;

(* Actualiza el estado previo de nuevoEvento *)
eventoPrevio := nuevoEvento;
END_FUNCTION_BLOCK