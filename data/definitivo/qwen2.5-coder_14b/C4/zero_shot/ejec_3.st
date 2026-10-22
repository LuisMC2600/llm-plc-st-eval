### Descripción del Bloque de Función

El bloque de función FB_D es un controlador de bombas diseñado para alternar el funcionamiento de dos bombas (bomba1 y bomba2) en función de una demanda de agua y dos posibles fallas (falla1 y falla2). El bloque opera según el estándar IEC 61131-3 y utiliza un temporizador de flanco ascendente (R_TRIG) para detectar cambios en la demanda. La lógica interna del bloque asegura que una sola bomba funcione a la vez, y que se alterne entre ellas en cada ciclo de demanda. Además, el bloque mantiene un registro de la falla que ha ocurrido (almFalla) para su posterior análisis o control. Este bloque sería útil en sistemas de bombeo de agua donde se requiere una redundancia y un control preciso de las bombas para evitar sobrecargas y garantizar un suministro constante de agua.

### Código con Comentarios Técnicos

```iec
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  // Indica si hay una demanda de agua
    falla1 : BOOL;   // Indica si la bomba1 ha fallado
    falla2 : BOOL;   // Indica si la bomba2 ha fallado
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   // Controla el funcionamiento de la bomba1
    bomba2 : BOOL;   // Controla el funcionamiento de la bomba2
    almFalla : BOOL; // Almacena la falla detectada
END_VAR
VAR
    turno : BOOL;    // Variable de estado para alternar entre bombas
    fDem : R_TRIG;   // Temporizador de flanco ascendente para detectar cambios en demanda
END_VAR

// Configura el temporizador de flanco ascendente con la señal de demanda
fDem(CLK := demanda);

// Si hay un flanco ascendente en la demanda
IF fDem.Q THEN
    // Alterna el estado del turno
    turno := NOT turno;
END_IF

// Si hay demanda de agua
IF demanda THEN
    // Si el turno está activo
    IF turno THEN
        // Activa bomba1 si no hay falla en bomba1
        bomba1 := NOT falla1;
        // Activa bomba2 si hay falla en bomba1 y no hay falla en bomba2
        bomba2 := falla1 AND NOT falla2;
        // Almacena la falla de bomba1 si hay falla
        almFalla := falla1;
    ELSE
        // Activa bomba2 si no hay falla en bomba2
        bomba2 := NOT falla2;
        // Activa bomba1 si hay falla en bomba2 y no hay falla en bomba1
        bomba1 := falla2 AND NOT falla1;
        // Almacena la falla de bomba2 si hay falla
        almFalla := falla2;
    END_IF
ELSE
    // Si no hay demanda, apaga ambas bombas
    bomba1 := FALSE;
    bomba2 := FALSE;
    // Limpia el registro de falla
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK
```