FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; // Entrada para habilitar o deshabilitar el semáforo
END_VAR_INPUT

VAR_OUTPUT
    luzV : BOOL; // Salida para la luz verde
    luzA : BOOL; // Salida para la luz amarilla
    luzR : BOOL; // Salida para la luz roja
END_VAR_OUTPUT

VAR
    estado : INT; // Estado actual del semáforo
    temporizador : TON; // Temporizador para controlar los tiempos de las luces
    parpadeo : BOOL; // Estado del parpadeo amarillo
END_VAR

// Inicialización del bloque de función
IF NOT habilitado THEN
    // Si no está habilitado, activar parpadeo amarillo
    luzV := FALSE;
    luzR := FALSE;
    temporizador(IN := TRUE, PT := T#1S);
    parpadeo := temporizador.Q;
    luzA := parpadeo;
ELSE
    // Si está habilitado, seguir la secuencia normal del semáforo
    temporizador(IN := TRUE);
    CASE estado OF
        0: // Luz verde
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            temporizador(PT := T#20S);
            IF temporizador.Q THEN
                estado := 1;
                temporizador(IN := FALSE);
            END_IF;
        1: // Luz amarilla
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            temporizador(PT := T#4S);
            IF temporizador.Q THEN
                estado := 2;
                temporizador(IN := FALSE);
            END_IF;
        2: // Luz roja
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            temporizador(PT := T#15S);
            IF temporizador.Q THEN
                estado := 0;
                temporizador(IN := FALSE);
            END_IF;
    ELSE
        // Reiniciar al estado inicial si el estado es desconocido
        estado := 0;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK