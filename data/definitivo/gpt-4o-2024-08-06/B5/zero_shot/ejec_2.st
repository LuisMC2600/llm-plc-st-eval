```pascal
FUNCTION_BLOCK FB_Ventilador
VAR
    // Variable de entrada: estado del quemador
    quemadorOn : BOOL;
    
    // Variable de salida: estado del ventilador
    ventilador : BOOL;
    
    // Temporizador para controlar el tiempo adicional de funcionamiento del ventilador
    timer : TON;
END_VAR

// Inicialización del temporizador con un tiempo de 30 segundos
timer(IN := NOT quemadorOn, PT := T#30S);

// Lógica para controlar el ventilador
IF quemadorOn THEN
    // Si el quemador está encendido, el ventilador también debe estar encendido
    ventilador := TRUE;
ELSE
    // Si el quemador está apagado, el ventilador sigue encendido hasta que el temporizador expire
    ventilador := NOT timer.Q;
END_IF;

// Actualización del temporizador
timer(IN := NOT quemadorOn);
```