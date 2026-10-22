FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Sensor de nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Salida para controlar la válvula
END_VAR

VAR
    timer : TON; // Timer de conteo ascendente
    estado : BOOL; // Estado de la válvula
END_VAR

// Inicialización del timer
IF NOT nivelAlto THEN
    timer(IN := FALSE);
    estado := FALSE;
END_IF;

// Control de la válvula
IF nivelAlto THEN
    timer(IN := TRUE, PT := T#5S);
    IF timer.Q THEN
        estado := TRUE;
    END_IF;
ELSE
    estado := FALSE;
    timer(IN := FALSE);
END_IF;

// Asignación de la salida
valvula := estado;