```pascal
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; // Estado del quemador (TRUE si encendido, FALSE si apagado)
END_VAR

VAR_OUTPUT
    ventilador : BOOL; // Estado del ventilador (TRUE si encendido, FALSE si apagado)
END_VAR

VAR
    timer : TON; // Timer de retardo
    timerDone : BOOL; // Bandera para indicar si el timer ha terminado
END_VAR

// Inicialización del timer
IF NOT timerDone THEN
    timer(IN := NOT quemadorOn, PT := T#30S);
    timerDone := timer.Q;
END_IF;

// Control del ventilador
IF quemadorOn OR (NOT quemadorOn AND NOT timerDone) THEN
    ventilador := TRUE;
ELSE
    ventilador := FALSE;
END_IF;
```

Este código implementa un FUNCTION_BLOCK llamado `FB_Ventilador` que controla el funcionamiento de un ventilador de enfriamiento en un horno. El ventilador se enciende cuando el quemador está encendido y continúa funcionando durante 30 segundos después de que el quemador se apague.