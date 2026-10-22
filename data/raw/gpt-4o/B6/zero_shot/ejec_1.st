```pascal
FUNCTION_BLOCK FB_Baliza
VAR
    alarma : BOOL; // Variable de entrada: indica si la alarma está activa
    lampara : BOOL; // Variable de salida: controla el estado de la lámpara
    ton : TON; // Temporizador TON para controlar el parpadeo
    estado_parpadeo : BOOL; // Estado interno para el parpadeo
END_VAR

// Inicialización del temporizador
ton(IN := estado_parpadeo, PT := T#1S);

// Lógica de control de la baliza
IF alarma THEN
    // Si la alarma está activa, alternar el estado de parpadeo
    IF ton.Q THEN
        estado_parpadeo := NOT estado_parpadeo; // Cambiar el estado de parpadeo
        ton(IN := FALSE); // Reiniciar el temporizador
    ELSE
        ton(IN := TRUE); // Activar el temporizador
    END_IF;
    lampara := estado_parpadeo; // Actualizar el estado de la lámpara
ELSE
    // Si no hay alarma, la lámpara está apagada
    lampara := FALSE;
    estado_parpadeo := FALSE; // Reiniciar el estado de parpadeo
    ton(IN := FALSE); // Asegurarse de que el temporizador esté desactivado
END_IF;
END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Baliza` que controla una lámpara de alarma. La lámpara parpadea cuando la alarma está activa, utilizando un temporizador para alternar el estado de la lámpara cada segundo. Si la alarma no está activa, la lámpara permanece apagada.