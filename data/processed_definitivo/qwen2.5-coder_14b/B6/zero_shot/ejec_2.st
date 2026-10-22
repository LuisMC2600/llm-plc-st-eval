FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Variable de entrada que indica si hay una alarma
END_VAR

VAR_OUTPUT
    lampara : BOOL; // Variable de salida que controla el estado de la lámpara
END_VAR

VAR
    timer : TON; // Timer de conteo hacia arriba
    estado : BOOL; // Estado actual de la lámpara (encendida/apagada)
END_VAR

// Inicialización del timer
IF timer.Q = FALSE THEN
    timer(IN := TRUE, PT := T#1S);
END_IF;

// Lógica de la baliza
IF alarma THEN
    // Si hay alarma, la lámpara parpadea
    lampara := estado;
    IF timer.Q THEN
        // Cambia el estado de la lámpara al final del ciclo de 1 segundo
        estado := NOT estado;
        timer(IN := FALSE); // Reinicia el timer
        timer(IN := TRUE); // Reinicia el timer
    END_IF;
ELSE
    // Si no hay alarma, la lámpara permanece apagada
    lampara := FALSE;
END_IF;
END_FUNCTION_BLOCK