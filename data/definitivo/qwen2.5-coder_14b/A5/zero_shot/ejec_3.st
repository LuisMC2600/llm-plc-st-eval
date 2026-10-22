```iec
FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT;        // Código del evento
    nuevoEvento : BOOL;  // Indica si se ha producido un nuevo evento
    ciclo : TIME;        // Tiempo de ejecución del bloque
END_VAR

VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento;  // Buffer circular de eventos
    indice : INT;                        // Índice del último evento registrado
    nEventos : INT;                      // Número de eventos válidos en el buffer
END_VAR

VAR
    tiempoAcumulado : TIME;  // Tiempo acumulado desde el arranque
    pos : INT;               // Posición actual en el buffer
END_VAR

TYPE ST_Evento :
STRUCT
    codigo : INT;  // Código del evento
    marca : TIME;   // Marca de tiempo del evento
END_STRUCT
END_TYPE

METHOD FB_Registro : VOID
    // Inicialización en el primer arranque
    IF NOT (indice = -1) THEN
        tiempoAcumulado := tiempoAcumulado + ciclo;
    END_IF;

    // Registro de nuevo evento
    IF nuevoEvento THEN
        // Guardar el evento en el buffer
        buffer[pos].codigo := evento;
        buffer[pos].marca := tiempoAcumulado;

        // Actualizar el índice y el número de eventos
        IF indice = -1 THEN
            indice := 0;
            nEventos := 1;
        ELSE
            indice := (indice + 1) MOD 20;
            IF nEventos < 20 THEN
                nEventos := nEventos + 1;
            END_IF;
        END_IF;

        // Actualizar la posición para el próximo evento
        pos := indice;
    END_IF;
END_METHOD
```

Este código define un FUNCTION_BLOCK llamado `FB_Registro` que cumple con los requisitos especificados. Incluye la declaración de la estructura `ST_Evento`, y el método `FB_Registro` que maneja el registro de eventos en un buffer circular.