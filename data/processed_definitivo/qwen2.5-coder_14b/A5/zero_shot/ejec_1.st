FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT;        // Código del evento
    nuevoEvento : BOOL;  // Indica si se ha producido un nuevo evento
    ciclo : TIME;       // Tiempo de ejecución del bloque
END_VAR

VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento;  // Buffer circular de eventos
    indice : INT;                        // Índice de la posición del último evento registrado
    nEventos : INT;                      // Número de eventos válidos en el buffer
END_VAR

VAR
    tiempoAcumulado : TIME;  // Tiempo acumulado desde el arranque del bloque
    primeraVez : BOOL := TRUE;  // Bandera para inicializar el tiempo acumulado
END_VAR

TYPE
    ST_Evento :
    STRUCT
        codigo : INT;  // Código del evento
        marca : TIME;  // Marca de tiempo del evento
    END_STRUCT
END_TYPE

// Inicialización del tiempo acumulado en la primera ejecución
IF primeraVez THEN
    tiempoAcumulado := T#0s;
    primeraVez := FALSE;
END_IF

// Actualización del tiempo acumulado
tiempoAcumulado := tiempoAcumulado + ciclo;

// Registro de un nuevo evento
IF nuevoEvento THEN
    // Incrementar el índice y ajustarlo al rango del buffer circular
    indice := (indice + 1) MOD 20;
    
    // Registrar el evento en la posición actual del índice
    buffer[indice].codigo := evento;
    buffer[indice].marca := tiempoAcumulado;
    
    // Actualizar el número de eventos válidos
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF
END_IF