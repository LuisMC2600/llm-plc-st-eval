FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; // Entrada que habilita o deshabilita el semáforo
END_VAR

VAR_OUTPUT
    luzV : BOOL; // Salida para la luz verde
    luzA : BOOL; // Salida para la luz amarilla
    luzR : BOOL; // Salida para la luz roja
END_VAR

VAR
    estado : INT := 0; // Variable de estado para el semáforo
    timer : TON; // Timer para controlar los tiempos
    tiempoVerde : TIME := T#20S; // Tiempo verde
    tiempoAmarillo : TIME := T#4S; // Tiempo amarillo
    tiempoRojo : TIME := T#15S; // Tiempo rojo
    tiempoAmarilloIntermitente : TIME := T#1S; // Tiempo amarillo intermitente
    contadorAmarilloIntermitente : INT := 0; // Contador para el amarillo intermitente
END_VAR

// Inicialización del timer
timer(IN := FALSE, PT := tiempoVerde);

// Máquina de estados
CASE estado OF
    0: // Estado verde
        luzV := TRUE;
        luzA := FALSE;
        luzR := FALSE;
        IF habilitado THEN
            timer(IN := TRUE);
            IF timer.Q THEN
                timer(IN := FALSE);
                estado := 1; // Cambiar a estado amarillo
            END_IF
        ELSE
            estado := 3; // Cambiar a estado amarillo intermitente
        END_IF

    1: // Estado amarillo
        luzV := FALSE;
        luzA := TRUE;
        luzR := FALSE;
        IF habilitado THEN
            timer(IN := TRUE, PT := tiempoAmarillo);
            IF timer.Q THEN
                timer(IN := FALSE);
                estado := 2; // Cambiar a estado rojo
            END_IF
        ELSE
            estado := 3; // Cambiar a estado amarillo intermitente
        END_IF

    2: // Estado rojo
        luzV := FALSE;
        luzA := FALSE;
        luzR := TRUE;
        IF habilitado THEN
            timer(IN := TRUE, PT := tiempoRojo);
            IF timer.Q THEN
                timer(IN := FALSE);
                estado := 0; // Cambiar a estado verde
            END_IF
        ELSE
            estado := 3; // Cambiar a estado amarillo intermitente
        END_IF

    3: // Estado amarillo intermitente
        luzV := FALSE;
        luzA := contadorAmarilloIntermitente MOD 2 = 0;
        luzR := FALSE;
        IF habilitado THEN
            estado := 0; // Reiniciar a estado verde
        ELSE
            contadorAmarilloIntermitente := contadorAmarilloIntermitente + 1;
            timer(IN := TRUE, PT := tiempoAmarilloIntermitente);
        END_IF
END_CASE