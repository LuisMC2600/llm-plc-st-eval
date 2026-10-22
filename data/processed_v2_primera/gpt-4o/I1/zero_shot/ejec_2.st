FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; // Entrada para habilitar o deshabilitar el semáforo
END_VAR

VAR_OUTPUT
    luzV : BOOL; // Salida para la luz verde
    luzA : BOOL; // Salida para la luz amarilla
    luzR : BOOL; // Salida para la luz roja
END_VAR

VAR
    timer : TON; // Temporizador para controlar los tiempos de las luces
    estado : INT; // Estado actual del semáforo
    parpadeo : BOOL; // Estado de parpadeo para la luz amarilla
END_VAR

// Inicialización de variables
IF NOT habilitado THEN
    // Si no está habilitado, activar el modo intermitente amarillo
    luzV := FALSE;
    luzR := FALSE;
    timer(IN := TRUE, PT := T#1S);
    
    IF timer.Q THEN
        parpadeo := NOT parpadeo; // Alternar el estado de parpadeo
        timer(IN := FALSE); // Reiniciar el temporizador
    END_IF
    
    luzA := parpadeo; // Luz amarilla intermitente
    estado := 0; // Reiniciar el estado para cuando se habilite de nuevo
ELSE
    // Si está habilitado, seguir la secuencia normal del semáforo
    CASE estado OF
        0: // Estado de luz verde
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            timer(IN := TRUE, PT := T#20S);
            
            IF timer.Q THEN
                estado := 1; // Cambiar al estado de luz amarilla
                timer(IN := FALSE); // Reiniciar el temporizador
            END_IF
            
        1: // Estado de luz amarilla
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            timer(IN := TRUE, PT := T#4S);
            
            IF timer.Q THEN
                estado := 2; // Cambiar al estado de luz roja
                timer(IN := FALSE); // Reiniciar el temporizador
            END_IF
            
        2: // Estado de luz roja
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            timer(IN := TRUE, PT := T#15S);
            
            IF timer.Q THEN
                estado := 0; // Volver al estado de luz verde
                timer(IN := FALSE); // Reiniciar el temporizador
            END_IF
    END_CASE
END_IF
END_FUNCTION_BLOCK