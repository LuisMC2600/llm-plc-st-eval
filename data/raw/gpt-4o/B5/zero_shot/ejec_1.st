```pascal
FUNCTION_BLOCK FB_Ventilador
VAR
    // Variable de entrada: estado del quemador
    quemadorOn : BOOL;
    
    // Variable de salida: estado del ventilador
    ventilador : BOOL;
    
    // Temporizador para controlar el tiempo de funcionamiento adicional del ventilador
    timer : TON;
    
    // Variable interna para almacenar el estado previo del quemador
    quemadorPrev : BOOL;
END_VAR

// Inicialización del temporizador
timer(IN := FALSE, PT := T#30S);

// Lógica del ventilador
IF quemadorOn THEN
    // Si el quemador está encendido, el ventilador debe estar encendido
    ventilador := TRUE;
    // Reiniciar el temporizador si el quemador está encendido
    timer(IN := FALSE);
ELSE
    // Si el quemador se apaga, iniciar el temporizador
    IF NOT quemadorPrev THEN
        timer(IN := TRUE);
    END_IF;
    
    // El ventilador sigue encendido mientras el temporizador está activo
    ventilador := timer.Q;
END_IF;

// Actualizar el estado previo del quemador
quemadorPrev := quemadorOn;
END_FUNCTION_BLOCK
```

Este código implementa la lógica requerida para controlar el ventilador de enfriamiento de un horno. El ventilador se mantiene encendido mientras el quemador está activo y continúa funcionando durante 30 segundos adicionales después de que el quemador se apaga.