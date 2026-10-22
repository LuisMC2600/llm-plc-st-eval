```pascal
FUNCTION_BLOCK FB_Semaforo
VAR
    // Variables de entrada
    habilitado : BOOL; // Indica si el semáforo está habilitado

    // Variables de salida
    luzV : BOOL := FALSE; // Luz verde
    luzA : BOOL := FALSE; // Luz amarilla
    luzR : BOOL := FALSE; // Luz roja

    // Variables internas
    estado : INT := 0; // Estado del semáforo
    temporizador : TON; // Temporizador para controlar los tiempos de las luces
    parpadeo : BOOL := FALSE; // Estado de parpadeo para luz amarilla intermitente
END_VAR

// Inicialización del temporizador
temporizador(IN := FALSE, PT := T#0S);

// Lógica del semáforo
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
    // Luz amarilla intermitente
    luzV := FALSE;
    luzR := FALSE;
    temporizador(IN := TRUE, PT := T#1S);
    IF temporizador.Q THEN
        parpadeo := NOT parpadeo;
        temporizador(IN := FALSE);
    END_IF;
    luzA := parpadeo;
    estado := 0; // Reinicia el estado para comenzar en verde al habilitar
END_IF;
END_FUNCTION_BLOCK
```