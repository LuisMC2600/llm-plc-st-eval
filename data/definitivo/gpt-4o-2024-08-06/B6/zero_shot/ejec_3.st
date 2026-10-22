```pascal
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Entrada que indica si hay una condición de alarma
END_VAR

VAR_OUTPUT
    lampara : BOOL; // Salida que controla el estado de la lámpara
END_VAR

VAR
    timerBlink : TON; // Temporizador para el parpadeo de la lámpara
    estadoParpadeo : BOOL; // Estado interno para el parpadeo
END_VAR

// Inicialización del temporizador
timerBlink(IN := estadoParpadeo, PT := T#1S);

// Lógica de control de la baliza
IF alarma THEN
    // Si hay alarma, alternar el estado de parpadeo cada segundo
    IF timerBlink.Q THEN
        estadoParpadeo := NOT estadoParpadeo;
        timerBlink(IN := FALSE); // Reiniciar el temporizador
    ELSE
        timerBlink(IN := TRUE); // Activar el temporizador
    END_IF;
    lampara := estadoParpadeo; // Actualizar el estado de la lámpara
ELSE
    // Si no hay alarma, la lámpara está apagada
    lampara := FALSE;
    estadoParpadeo := FALSE; // Reiniciar el estado de parpadeo
    timerBlink(IN := FALSE); // Asegurarse de que el temporizador esté desactivado
END_IF;
END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Baliza` que controla una lámpara de alarma. La lámpara parpadea cuando la condición de alarma está activa, utilizando un temporizador para alternar el estado de la lámpara cada segundo. Cuando no hay alarma, la lámpara permanece apagada.