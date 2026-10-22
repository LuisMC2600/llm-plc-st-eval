TYPE ST_Evento :
STRUCT
    codigo : INT;  (* Código del evento *)
    marca  : TIME; (* Tiempo acumulado en el momento del evento *)
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento      : INT;  (* Valor del evento a registrar *)
    nuevoEvento : BOOL; (* Señal para registrar un nuevo evento (flanco de subida) *)
    ciclo       : TIME; (* Período de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    buffer      : ARRAY[0..19] OF ST_Evento; (* Arreglo circular de eventos *)
    indice      : INT := -1;                 (* Posición del último evento registrado (-1 si no hay) *)
    nEventos    : INT := 0;                  (* Número de eventos válidos en el buffer (0 a 20) *)
END_VAR

VAR
    tiempoAcumulado : TIME := T#0s;  (* Tiempo acumulado desde el arranque *)
    prevNuevoEvento : BOOL := FALSE; (* Memoria para detectar el flanco de subida *)
END_VAR

(* Acumular el tiempo de ciclo en cada ejecución *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detectar transición de FALSE a TRUE en nuevoEvento *)
IF nuevoEvento AND NOT prevNuevoEvento THEN
    
    (* Incrementar índice y aplicar lógica de buffer circular *)
    indice := indice + 1;
    IF indice > 19 THEN
        indice := 0;
    END_IF;
    
    (* Registrar el evento y la marca de tiempo en la posición actual *)
    buffer[indice].codigo := evento;
    buffer[indice].marca  := tiempoAcumulado;
    
    (* Incrementar el contador de eventos válidos hasta un máximo de 20 *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;
    
END_IF;

(* Guardar el estado actual para la detección de flanco en el próximo ciclo *)
prevNuevoEvento := nuevoEvento;

END_FUNCTION_BLOCK