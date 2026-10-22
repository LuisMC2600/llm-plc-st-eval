FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT; (* Código del evento *)
    nuevoEvento : BOOL; (* Indica si se ha producido un nuevo evento *)
    ciclo : TIME; (* Tiempo de ciclo de ejecución *)
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer de eventos *)
    indice : INT; (* Índice del último evento registrado *)
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

(* Registro de eventos *)
IF nuevoEvento AND NOT eventoAnterior THEN
    IF indice = -1 THEN
        indice := 0;
    ELSE
        indice := (indice + 1) MOD 20;
    END_IF

    buffer[indice].codigo := evento;
    buffer[indice].marca := tiempoAcumulado;

    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF
END_IF

(* Actualización del estado anterior de nuevoEvento *)
eventoAnterior := nuevoEvento;
END_FUNCTION_BLOCK