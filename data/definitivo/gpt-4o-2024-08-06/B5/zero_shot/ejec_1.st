```pascal
FUNCTION_BLOCK FB_Ventilador
VAR
    // Variable de entrada
    quemadorOn : BOOL; // Estado del quemador: TRUE si está encendido, FALSE si está apagado

    // Variable de salida
    ventilador : BOOL; // Estado del ventilador: TRUE si está encendido, FALSE si está apagado

    // Variables internas
    timer : TON; // Temporizador para controlar el tiempo adicional de funcionamiento del ventilador
END_VAR

// Lógica del ventilador
IF quemadorOn THEN
    // Si el quemador está encendido, el ventilador debe estar encendido
    ventilador := TRUE;
    // Reiniciar el temporizador
    timer(IN := FALSE);
ELSE
    // Si el quemador está apagado, iniciar el temporizador
    timer(IN := TRUE, PT := T#30S);
    // El ventilador sigue encendido mientras el temporizador no haya alcanzado el tiempo establecido
    ventilador := timer.Q;
END_IF
END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Ventilador` que controla el estado de un ventilador de enfriamiento basado en el estado de un quemador. Utiliza un temporizador `TON` para mantener el ventilador encendido durante 30 segundos adicionales después de que el quemador se apague.