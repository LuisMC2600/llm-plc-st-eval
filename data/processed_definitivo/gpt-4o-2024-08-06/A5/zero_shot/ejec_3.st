// Declaración del tipo de datos ST_Evento
TYPE ST_Evento :
STRUCT
    codigo : INT;   // Código del evento
    marca  : TIME;  // Marca de tiempo del evento
END_STRUCT
END_TYPE

// Declaración del bloque de función FB_Registro
FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento     : INT;   // Código del evento a registrar
    nuevoEvento: BOOL;  // Indica si hay un nuevo evento
    ciclo      : TIME;  // Tiempo de ciclo de ejecución
END_VAR_INPUT

VAR_OUTPUT
    buffer     : ARRAY[0..19] OF ST_Evento; // Buffer circular de eventos
    indice     : INT := -1;                 // Índice del último evento registrado
    nEventos   : INT := 0;                  // Número de eventos registrados
END_VAR_OUTPUT

VAR
    tiempoAcumulado : TIME := T#0s;         // Tiempo acumulado desde el arranque
    nuevoEventoAnt  : BOOL := FALSE;        // Estado anterior de nuevoEvento
END_VAR

// Cuerpo del bloque de función
BEGIN
    // Actualizar el tiempo acumulado
    tiempoAcumulado := tiempoAcumulado + ciclo;

    // Detectar flanco ascendente de nuevoEvento
    IF (nuevoEvento AND NOT nuevoEventoAnt) THEN
        // Incrementar el índice circularmente
        indice := (indice + 1) MOD 20;

        // Registrar el nuevo evento en el buffer
        buffer[indice].codigo := evento;
        buffer[indice].marca  := tiempoAcumulado;

        // Actualizar el número de eventos registrados
        IF nEventos < 20 THEN
            nEventos := nEventos + 1;
        END_IF
    END_IF

    // Actualizar el estado anterior de nuevoEvento
    nuevoEventoAnt := nuevoEvento;
END_FUNCTION_BLOCK