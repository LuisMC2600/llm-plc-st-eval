```pascal
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Variable de entrada que indica si hay una condición de alarma
END_VAR

VAR_OUTPUT
    lampara : BOOL; // Variable de salida que controla el estado de la lámpara
END_VAR

VAR
    ton : TON; // Temporizador para controlar el parpadeo
    estado : BOOL; // Estado interno para alternar el parpadeo
END_VAR

// Inicialización del temporizador
ton(IN := estado, PT := T#1S);

// Lógica de control de la baliza
IF alarma THEN
    // Si la alarma está activa, alternar el estado de la lámpara
    IF ton.Q THEN
        estado := NOT estado; // Cambiar el estado interno
        ton(IN := FALSE); // Reiniciar el temporizador
    ELSE
        ton(IN := TRUE); // Activar el temporizador
    END_IF;
    lampara := estado; // Actualizar el estado de la lámpara
ELSE
    // Si no hay alarma, la lámpara permanece apagada
    lampara := FALSE;
    estado := FALSE; // Reiniciar el estado interno
    ton(IN := FALSE); // Asegurarse de que el temporizador esté apagado
END_IF;

END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Baliza` que controla una lámpara de alarma. Cuando la alarma está activa, la lámpara parpadea con un ciclo de 1 segundo encendida y 1 segundo apagada. Si no hay alarma, la lámpara permanece apagada. El temporizador `TON` se utiliza para gestionar el tiempo de parpadeo.