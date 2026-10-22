```iecst
TYPE ST_Evento :
STRUCT
    codigo : INT;   (* Código del evento *)
    marca  : TIME;  (* Tiempo acumulado en el momento del evento *)
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento      : INT;      (* Código del evento a registrar *)
    nuevoEvento : BOOL;     (* Disparador para registrar el evento (flanco de subida) *)
    ciclo       : TIME;     (* Período de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    buffer      : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice      : INT := -1;                 (* Índice del último evento registrado (-1 si está vacío) *)
    nEventos    : INT := 0;                  (* Cantidad de eventos válidos en el buffer (0 a 20) *)
END_VAR

VAR
    tiempoAcumulado : TIME := T#0s;          (* Tiempo total acumulado desde el arranque *)
    prevNuevoEvento : BOOL := FALSE;         (* Memoria para detectar el flanco de subida *)
END_VAR

(* 1. Acumular el tiempo de ejecución en cada ciclo *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* 2. Detectar transición de FALSE a TRUE en nuevoEvento *)
IF nuevoEvento AND NOT prevNuevoEvento THEN
    
    (* 3. Calcular el nuevo índice (buffer circular de 0 a 19) *)
    indice := indice + 1;
    IF indice > 19 THEN
        indice := 0;
    END_IF;
    
    (* 4. Registrar los datos en el buffer *)
    buffer[indice].codigo := evento;
    buffer[indice].marca  := tiempoAcumulado;
    
    (* 5. Actualizar la cantidad de eventos válidos (tope en 20) *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;
    
END_IF;

(* 6. Actualizar la memoria del flanco para el siguiente ciclo *)
prevNuevoEvento := nuevoEvento;

END_FUNCTION_BLOCK
```