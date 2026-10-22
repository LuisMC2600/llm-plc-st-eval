Aquí tienes el código en Structured Text (ST) para el FUNCTION_BLOCK llamado `FB_Registro`, que implementa un registro de eventos en un buffer circular conforme a tu descripción:

```pascal
// Declaración del tipo de datos para el evento
TYPE ST_Evento :
STRUCT
    codigo : INT;   // Código del evento
    marca  : TIME;  // Marca de tiempo del evento
END_STRUCT
END_TYPE

// Declaración del bloque de función
FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento     : INT;   // Código del evento entrante
    nuevoEvento: BOOL;  // Indica si hay un nuevo evento
    ciclo      : TIME;  // Período de ejecución del bloque
END_VAR
VAR_OUTPUT
    buffer     : ARRAY[0..19] OF ST_Evento; // Buffer circular de eventos
    indice     : INT := -1;                 // Índice del último evento registrado
    nEventos   : INT := 0;                  // Número de eventos registrados
END_VAR
VAR
    tiempoAcumulado : TIME := T#0s;         // Tiempo acumulado desde el arranque
    nuevoEventoPrev : BOOL := FALSE;        // Estado anterior de nuevoEvento
END_VAR

// Cuerpo del bloque de función
BEGIN
    // Actualizar el tiempo acumulado
    tiempoAcumulado := tiempoAcumulado + ciclo;

    // Detectar transición de FALSE a TRUE en nuevoEvento
    IF (nuevoEvento AND NOT nuevoEventoPrev) THEN
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
    nuevoEventoPrev := nuevoEvento;
END_FUNCTION_BLOCK
```

### Explicación breve:
- **ST_Evento**: Define la estructura de un evento con un código y una marca de tiempo.
- **FB_Registro**: Es el bloque de función que gestiona el registro de eventos.
- **Variables de entrada**: `evento`, `nuevoEvento`, y `ciclo`.
- **Variables de salida**: `buffer`, `indice`, y `nEventos`.
- **Variables internas**: `tiempoAcumulado` para el tiempo total desde el arranque y `nuevoEventoPrev` para detectar la transición de `nuevoEvento`.
- **Lógica**: Se actualiza el tiempo acumulado, se detecta la transición de `nuevoEvento`, se actualiza el índice y se registra el evento en el buffer. Se ajusta el número de eventos registrados y se actualiza el estado anterior de `nuevoEvento`.