```pascal
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Sensor de nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Control de la válvula
END_VAR

VAR
    timer : TON; // Timer de 5 segundos
    estado : BOOL; // Estado de la válvula
END_VAR

// Inicialización del timer
IF NOT nivelAlto THEN
    timer(IN := FALSE);
    estado := FALSE;
END_IF;

// Control de la válvula
IF nivelAlto THEN
    timer(IN := TRUE);
    IF timer.Q THEN
        estado := TRUE;
    END_IF;
ELSE
    estado := FALSE;
    timer(IN := FALSE);
END_IF;

// Asignación de la salida
valvula := estado;
```

Este código implementa un FUNCTION_BLOCK llamado `FB_Valvula` que controla una válvula de drenaje de un tanque. La válvula se abre cuando el sensor de nivel alto (`nivelAlto`) permanece activo durante 5 segundos continuos, y se cierra inmediatamente si el nivel deja de estar alto. El timer se utiliza para medir los 5 segundos, y el estado de la válvula se actualiza según las condiciones especificadas.