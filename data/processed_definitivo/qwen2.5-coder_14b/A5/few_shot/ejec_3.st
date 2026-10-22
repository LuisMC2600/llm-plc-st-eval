FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT; (* Código del evento *)
    nuevoEvento : BOOL; (* Indica si se debe registrar un nuevo evento *)
    ciclo : TIME; (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice : INT; (* Índice de la posición del último evento registrado *)
    nEventos : INT; (* Número de eventos válidos en el buffer *)
END_VAR
VAR
    tiempoAcumulado : TIME := T#0s; (* Tiempo acumulado desde el arranque *)
    eventoAnterior : BOOL := FALSE; (* Estado anterior de nuevoEvento *)
END_VAR

(* Definición de la estructura ST_Evento *)
TYPE ST_Evento :
STRUCT
    codigo : INT; (* Código del evento *)
    marca : TIME; (* Marca de tiempo del evento *)
END_STRUCT
END_TYPE

(* Acumulación del tiempo *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Registro de nuevo evento *)
IF nuevoEvento AND NOT eventoAnterior THEN
    (* Incrementar el índice y ajustarlo al rango del buffer *)
    indice := (indice + 1) MOD 20;
    
    (* Registrar el evento en el buffer *)
    buffer[indice].codigo := evento;
    buffer[indice].marca := tiempoAcumulado;
    
    (* Actualizar el número de eventos válidos *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;
END_IF;

(* Actualizar el estado anterior de nuevoEvento *)
eventoAnterior := nuevoEvento;
END_FUNCTION_BLOCK