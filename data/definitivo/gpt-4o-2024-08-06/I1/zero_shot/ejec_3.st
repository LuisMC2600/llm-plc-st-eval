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
    estado : INT := 0; // Estado del semáforo
    temporizador : TON; // Temporizador para manejar los tiempos
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
    estado := 0; // Reiniciar secuencia al habilitar
END_IF;
END_FUNCTION_BLOCK
```

Este código implementa un semáforo vehicular cíclico en un bloque de función llamado `FB_Semaforo`. Utiliza un temporizador para controlar la duración de cada luz y cambia de estado según el tiempo transcurrido. Cuando la entrada `habilitado` está desactivada, el semáforo entra en un modo de parpadeo amarillo. Al reactivarse, la secuencia comienza nuevamente con la luz verde.