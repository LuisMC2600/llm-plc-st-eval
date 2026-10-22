```pascal
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Variable de entrada que indica si la alarma está activa
END_VAR

VAR_OUTPUT
    lampara : BOOL; // Variable de salida que controla el estado de la lámpara
END_VAR

VAR
    timerBlink : TON; // Temporizador para controlar el parpadeo
    estadoParpadeo : BOOL; // Estado interno para alternar el parpadeo
END_VAR

// Inicialización del temporizador
timerBlink(IN := estadoParpadeo, PT := T#1S);

IF alarma THEN
    // Si la alarma está activa, controlar el parpadeo
    IF timerBlink.Q THEN
        estadoParpadeo := NOT estadoParpadeo; // Alternar el estado de parpadeo
        timerBlink(IN := estadoParpadeo); // Reiniciar el temporizador
    END_IF;
    lampara := estadoParpadeo; // Actualizar la salida de la lámpara
ELSE
    // Si no hay alarma, la lámpara permanece apagada
    lampara := FALSE;
    estadoParpadeo := FALSE; // Reiniciar el estado de parpadeo
    timerBlink(IN := FALSE); // Asegurarse de que el temporizador esté detenido
END_IF;

END_FUNCTION_BLOCK
```

Este código implementa un bloque de función `FB_Baliza` que controla el parpadeo de una lámpara de alarma. Cuando la alarma está activa, la lámpara parpadea con un ciclo de 1 segundo encendida y 1 segundo apagada. Cuando no hay alarma, la lámpara permanece apagada. El temporizador `TON` se utiliza para gestionar el tiempo de parpadeo.