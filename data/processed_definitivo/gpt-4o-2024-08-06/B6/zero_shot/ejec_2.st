FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Variable de entrada que indica si hay una condición de alarma
END_VAR

VAR_OUTPUT
    lampara : BOOL; // Variable de salida que controla el estado de la lámpara
END_VAR

VAR
    temporizador : TON; // Temporizador para controlar el parpadeo
    estado_parpadeo : BOOL; // Estado interno para alternar el parpadeo
END_VAR

// Inicialización del temporizador
temporizador(IN := estado_parpadeo, PT := T#1S);

IF alarma THEN
    // Si hay alarma, activar el temporizador
    temporizador(IN := NOT temporizador.Q);
    
    // Alternar el estado de parpadeo cuando el temporizador termina
    IF temporizador.Q THEN
        estado_parpadeo := NOT estado_parpadeo;
    END_IF;
    
    // La lámpara sigue el estado de parpadeo
    lampara := estado_parpadeo;
ELSE
    // Si no hay alarma, apagar la lámpara y reiniciar el temporizador
    lampara := FALSE;
    estado_parpadeo := FALSE;
    temporizador(IN := FALSE);
END_IF;

END_FUNCTION_BLOCK