```pascal
// Declaración del tipo de datos para un evento
TYPE ST_Evento :
STRUCT
    codigo : INT;   // Código del evento
    marca  : TIME;  // Marca de tiempo del evento
END_STRUCT
END_TYPE

// Declaración del bloque de función FB_Registro
FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento     : INT;   // Código del evento entrante
    nuevoEvento: BOOL;  // Indica si hay un nuevo evento
    ciclo      : TIME;  // Período de ejecución del bloque
END_VAR_INPUT

VAR_OUTPUT
    buffer     : ARRAY[0..19] OF ST_Evento; // Buffer circular de eventos
    indice     : INT := -1;                 // Índice del último evento registrado
    nEventos   : INT := 0;                  // Número de eventos registrados
END_VAR_OUTPUT

VAR
    tiempoAcumulado : TIME := T#0s; // Tiempo acumulado desde el arranque
    nuevoEventoPrev : BOOL := FALSE; // Estado anterior de nuevoEvento
END_VAR

// Cuerpo del bloque de función
BEGIN
    // Actualizar el tiempo acumulado
    tiempoAcumulado := tiempoAcumulado + ciclo;

    // Detectar transición de FALSE a TRUE en nuevoEvento
    IF (nuevoEvento AND NOT nuevoEventoPrev) THEN
        // Incrementar el índice circular
        indice := (indice + 1) MOD 20;

        // Registrar el evento en el buffer
        buffer[indice].codigo := evento;
        buffer[indice].marca  := tiempoAcumulado;

        // Actualizar el número de eventos registrados
        IF nEventos < 20 THEN
            nEventos := nEventos + 1;
        END_IF
    END_IF

    // Actualizar el estado anterior de nuevoEvento
    nuevoEventoPrev := nuevoEvento;
END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Registro` que gestiona un registro de eventos en un buffer circular. La estructura `ST_Evento` almacena el código y la marca de tiempo de cada evento. El bloque actualiza el tiempo acumulado y registra nuevos eventos cuando se detecta una transición de `FALSE` a `TRUE` en la entrada `nuevoEvento`. El buffer se maneja de manera circular, sobrescribiendo los eventos más antiguos cuando está lleno.