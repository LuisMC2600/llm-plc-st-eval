FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Variable de entrada que indica si hay una alarma
END_VAR

VAR_OUTPUT
    lampara : BOOL; // Variable de salida que controla el estado de la lámpara
END_VAR

VAR
    estado : BOOL := FALSE; // Variable interna para controlar el estado de parpadeo
    timer : TON; // Timer para controlar el ciclo de parpadeo
END_VAR

// Configuración del timer para un ciclo de 1 segundo
timer(IN := TRUE, PT := T#1S);

// Lógica para controlar el estado de la lámpara
IF alarma THEN
    // Si hay alarma, la lámpara parpadea
    lampara := estado;
    // Cambiar el estado de la lámpara al final del ciclo del timer
    IF timer.Q THEN
        estado := NOT estado;
        timer(IN := FALSE); // Reiniciar el timer
    END_IF
ELSE
    // Si no hay alarma, la lámpara permanece apagada
    lampara := FALSE;
END_IF