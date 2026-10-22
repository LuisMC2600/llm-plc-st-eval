```pascal
FUNCTION_BLOCK FB_Ventilador
VAR
    // Variable de entrada: indica si el quemador está encendido
    quemadorOn : BOOL;
    
    // Variable de salida: controla el estado del ventilador
    ventilador : BOOL;
    
    // Temporizador para controlar el tiempo adicional de funcionamiento del ventilador
    timer : TON;
    
    // Variable interna para almacenar el estado anterior del quemador
    quemadorPrev : BOOL;
END_VAR

// Inicialización del temporizador
timer(IN := FALSE, PT := T#30S);

// Lógica de control del ventilador
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
    
    // El ventilador sigue encendido mientras el temporizador no haya alcanzado el tiempo preestablecido
    ventilador := NOT timer.Q;
END_IF;

// Actualizar el estado anterior del quemador
quemadorPrev := quemadorOn;
END_FUNCTION_BLOCK
```