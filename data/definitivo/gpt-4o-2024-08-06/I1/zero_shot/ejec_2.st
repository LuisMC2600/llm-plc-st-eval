```pascal
FUNCTION_BLOCK FB_Semaforo
VAR
    // Variables de entrada
    habilitado : BOOL; // Entrada para habilitar o deshabilitar el semáforo

    // Variables de salida
    luzV : BOOL; // Luz verde
    luzA : BOOL; // Luz amarilla
    luzR : BOOL; // Luz roja

    // Variables internas
    estado : INT := 0; // Estado del semáforo
    temporizador : TON; // Temporizador para controlar los tiempos de las luces
    tiempoParpadeo : TON; // Temporizador para el parpadeo del amarillo
END_VAR

// Inicialización del temporizador
temporizador(IN := FALSE, PT := T#0S);
tiempoParpadeo(IN := FALSE, PT := T#0S);

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
                temporizador(IN := FALSE);
                estado := 1;
            END_IF;
        1: // Luz amarilla
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            temporizador(IN := TRUE, PT := T#4S);
            IF temporizador.Q THEN
                temporizador(IN := FALSE);
                estado := 2;
            END_IF;
        2: // Luz roja
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            temporizador(IN := TRUE, PT := T#15S);
            IF temporizador.Q THEN
                temporizador(IN := FALSE);
                estado := 0;
            END_IF;
    END_CASE;
ELSE
    // Modo amarillo intermitente
    luzV := FALSE;
    luzR := FALSE;
    tiempoParpadeo(IN := TRUE, PT := T#1S);
    IF tiempoParpadeo.Q THEN
        luzA := NOT luzA; // Alterna el estado de la luz amarilla
        tiempoParpadeo(IN := FALSE);
    END_IF;
    estado := 0; // Reinicia el estado para comenzar en verde cuando se habilite
END_IF;
END_FUNCTION_BLOCK
```