FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; // Variable de entrada que indica si el semáforo está habilitado
END_VAR

VAR_OUTPUT
    luzV : BOOL; // Variable de salida para la luz verde
    luzA : BOOL; // Variable de salida para la luz amarilla
    luzR : BOOL; // Variable de salida para la luz roja
END_VAR

VAR
    estado : INT := 0; // Variable de estado para controlar la secuencia del semáforo
    timer : TON; // Timer para controlar los tiempos de cada estado
    intermitente : BOOL := FALSE; // Variable para controlar el estado intermitente de la luz amarilla
END_VAR

// Inicialización del timer
timer(IN := TRUE, PT := T#20S);

// Máquina de estados
CASE estado OF
    0: // Estado verde
        luzV := TRUE;
        luzA := FALSE;
        luzR := FALSE;
        IF habilitado THEN
            IF timer.Q THEN
                timer(PT := T#4S); // Cambiar a amarillo después de 20 segundos
                estado := 1;
            END_IF
        ELSE
            estado := 3; // Cambiar a estado intermitente si habilitado se desactiva
        END_IF

    1: // Estado amarillo
        luzV := FALSE;
        luzA := TRUE;
        luzR := FALSE;
        IF habilitado THEN
            IF timer.Q THEN
                timer(PT := T#15S); // Cambiar a rojo después de 4 segundos
                estado := 2;
            END_IF
        ELSE
            estado := 3; // Cambiar a estado intermitente si habilitado se desactiva
        END_IF

    2: // Estado rojo
        luzV := FALSE;
        luzA := FALSE;
        luzR := TRUE;
        IF habilitado THEN
            IF timer.Q THEN
                timer(PT := T#20S); // Cambiar a verde después de 15 segundos
                estado := 0;
            END_IF
        ELSE
            estado := 3; // Cambiar a estado intermitente si habilitado se desactiva
        END_IF

    3: // Estado intermitente
        luzV := FALSE;
        luzA := intermitente;
        luzR := FALSE;
        IF habilitado THEN
            estado := 0; // Reiniciar la secuencia si habilitado se activa
        ELSE
            intermitente := NOT intermitente; // Cambiar el estado de intermitencia cada segundo
            timer(PT := T#1S); // Reiniciar el timer para el siguiente cambio de estado
        END_IF
END_CASE