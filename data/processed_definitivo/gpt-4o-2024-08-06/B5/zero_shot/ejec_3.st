FUNCTION_BLOCK FB_Ventilador
VAR
    quemadorOn : BOOL; // Variable de entrada: estado del quemador
    ventilador : BOOL; // Variable de salida: estado del ventilador
    timer : TON; // Temporizador para controlar el tiempo de enfriamiento
END_VAR

// Inicialización del temporizador
timer(IN := FALSE, PT := T#30S);

IF quemadorOn THEN
    // Si el quemador está encendido, el ventilador debe estar encendido
    ventilador := TRUE;
    timer(IN := FALSE); // Asegurarse de que el temporizador esté apagado
ELSE
    // Si el quemador está apagado, iniciar el temporizador
    timer(IN := TRUE);
    IF timer.Q THEN
        // Si el temporizador ha terminado, apagar el ventilador
        ventilador := FALSE;
    ELSE
        // Mientras el temporizador no haya terminado, mantener el ventilador encendido
        ventilador := TRUE;
    END_IF
END_IF
END_FUNCTION_BLOCK