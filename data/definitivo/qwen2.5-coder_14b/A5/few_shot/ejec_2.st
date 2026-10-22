```structured-text
TYPE ST_Evento :
STRUCT
    codigo : INT; (* Código del evento *)
    marca : TIME; (* Marca de tiempo del evento *)
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT; (* Código del evento *)
    nuevoEvento : BOOL; (* Indica si se debe registrar un nuevo evento *)
    ciclo : TIME; (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer de eventos *)
    indice : INT; (* Índice del último evento registrado *)
    nEventos : INT; (* Número de eventos válidos en el buffer *)
END_VAR
VAR
    tiempoAcumulado : TIME := T#0s; (* Tiempo acumulado desde el arranque *)
    ultimoEvento : INT := -1; (* Índice del último evento registrado *)
    eventosRegistrados : INT := 0; (* Número de eventos registrados *)
END_VAR

(* Acumula el tiempo de ciclo *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Registro de nuevo evento *)
IF nuevoEvento THEN
    (* Incrementa el índice y ajusta si se llena el buffer *)
    ultimoEvento := (ultimoEvento + 1) MOD 20;
    
    (* Registra el evento en el buffer *)
    buffer[ultimoEvento].codigo := evento;
    buffer[ultimoEvento].marca := tiempoAcumulado;
    
    (* Actualiza el número de eventos válidos *)
    IF eventosRegistrados < 20 THEN
        eventosRegistrados := eventosRegistrados + 1;
    END_IF;
    
    (* Actualiza el índice y el número de eventos *)
    indice := ultimoEvento;
    nEventos := eventosRegistrados;
END_IF
END_FUNCTION_BLOCK
```