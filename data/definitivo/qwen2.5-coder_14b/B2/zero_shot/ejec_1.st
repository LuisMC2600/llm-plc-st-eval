```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Sensor de nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Salida para controlar la válvula
END_VAR

VAR
    timer : TON; // Timer de retardo
    estado : BOOL; // Estado de la válvula
END_VAR

// Inicialización del timer
IF timer.Q = FALSE THEN
    timer(IN := nivelAlto, PT := T#5S);
END_IF;

// Control de la válvula
IF nivelAlto THEN
    // Si el nivel está alto y el timer ha terminado, abrir la válvula
    IF timer.Q THEN
        estado := TRUE;
    END_IF;
ELSE
    // Si el nivel no está alto, cerrar la válvula inmediatamente
    estado := FALSE;
    timer(IN := FALSE); // Reiniciar el timer
END_IF;

// Asignar el estado de la válvula a la salida
valvula := estado;
```

Este código implementa un control de válvula de drenaje utilizando un FUNCTION_BLOCK en Structured Text (ST) conforme al estándar IEC 61131-3. La lógica del programa asegura que la válvula se abra solo después de que el sensor de nivel alto permanezca activo durante 5 segundos, y se cierra inmediatamente si el nivel deja de estar alto.