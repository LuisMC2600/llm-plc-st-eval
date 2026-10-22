```pascal
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Variable de entrada que indica si hay una condición de alarma
END_VAR

VAR_OUTPUT
    lampara : BOOL; // Variable de salida que controla el estado de la lámpara
END_VAR

VAR
    temporizador : TON; // Temporizador para controlar el parpadeo
    estado_parpadeo : BOOL; // Estado interno para el parpadeo
END_VAR

// Inicialización del temporizador
temporizador(IN := estado_parpadeo, PT := T#1S);

// Lógica de control de la baliza
IF alarma THEN
    temporizador(IN := NOT temporizador.Q); // Alterna el estado del temporizador
    estado_parpadeo := temporizador.Q; // Actualiza el estado de parpadeo
    lampara := estado_parpadeo; // La lámpara sigue el estado de parpadeo
ELSE
    temporizador(IN := FALSE); // Resetea el temporizador si no hay alarma
    estado_parpadeo := FALSE; // Asegura que el estado de parpadeo esté apagado
    lampara := FALSE; // Apaga la lámpara si no hay alarma
END_IF
END_FUNCTION_BLOCK
```

Este código implementa un bloque de función `FB_Baliza` que controla una lámpara de alarma. Cuando la entrada `alarma` es verdadera, la lámpara parpadea con un ciclo de 1 segundo encendida y 1 segundo apagada. Si no hay alarma, la lámpara permanece apagada.