```iecst
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Condición de alarma activa
END_VAR
VAR_OUTPUT
    lampara : BOOL; // Salida hacia la baliza luminosa
END_VAR
VAR
    Timer_ON : TON; // Temporizador para el tiempo de encendido (1s)
    Timer_OFF : TON; // Temporizador para el tiempo de apagado (1s)
END_VAR

// Temporizador que cuenta el tiempo que la lámpara permanece encendida
Timer_ON(IN := alarma AND NOT Timer_OFF.Q, PT := T#1S);

// Temporizador que cuenta el tiempo que la lámpara permanece apagada
Timer_OFF(IN := Timer_ON.Q, PT := T#1S);

// La lámpara enciende inmediatamente con la alarma y alterna su estado cada segundo
lampara := alarma AND NOT Timer_ON.Q;

END_FUNCTION_BLOCK
```