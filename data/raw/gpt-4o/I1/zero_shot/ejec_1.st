```pascal
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
    estado : INT := 0; // Estado actual del semáforo
    temporizador : TON; // Temporizador para controlar los tiempos de cada luz
    parpadeo : BOOL := FALSE; // Estado del parpadeo amarillo
END_VAR

// Inicialización del temporizador
temporizador(IN := FALSE, PT := T#0S);

IF habilitado THEN
    // Secuencia cíclica del semáforo
    CASE estado OF
        0: // Luz verde
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            temporizador(IN := TRUE, PT := T#20S);
            IF temporizador.Q THEN
                estado := 1;
                temporizador(IN := FALSE);
            END_IF;
        1: // Luz amarilla
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            temporizador(IN := TRUE, PT := T#4S);
            IF temporizador.Q THEN
                estado := 2;
                temporizador(IN := FALSE);
            END_IF;
        2: // Luz roja
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            temporizador(IN := TRUE, PT := T#15S);
            IF temporizador.Q THEN
                estado := 0;
                temporizador(IN := FALSE);
            END_IF;
    END_CASE;
ELSE
    // Modo amarillo intermitente
    luzV := FALSE;
    luzR := FALSE;
    temporizador(IN := TRUE, PT := T#1S);
    IF temporizador.Q THEN
        parpadeo := NOT parpadeo;
        temporizador(IN := FALSE);
    END_IF;
    luzA := parpadeo;
    estado := 0; // Reiniciar la secuencia al habilitarse de nuevo
END_IF;
END_FUNCTION_BLOCK
```