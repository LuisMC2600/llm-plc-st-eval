```pascal
FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; // Variable de entrada que indica si el semáforo está habilitado
END_VAR

VAR_OUTPUT
    luzV : BOOL; // Salida para la luz verde
    luzA : BOOL; // Salida para la luz amarilla
    luzR : BOOL; // Salida para la luz roja
END_VAR

VAR
    estado : INT := 0; // Variable de estado para controlar la secuencia
    contador : TON; // Contador de tiempo
    intermitente : BOOL := FALSE; // Variable para controlar el estado intermitente
END_VAR

// Inicialización del contador de tiempo
contador(IN := FALSE, PT := T#1S);

// Lógica del semáforo
CASE estado OF
    0: // Estado verde
        IF habilitado THEN
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            contador(IN := TRUE, PT := T#20S);
            IF contador.Q THEN
                estado := 1;
            END_IF;
        ELSE
            estado := 3; // Cambia a estado intermitente
        END_IF;
        
    1: // Estado amarillo
        IF habilitado THEN
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            contador(IN := TRUE, PT := T#4S);
            IF contador.Q THEN
                estado := 2;
            END_IF;
        ELSE
            estado := 3; // Cambia a estado intermitente
        END_IF;
        
    2: // Estado rojo
        IF habilitado THEN
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            contador(IN := TRUE, PT := T#15S);
            IF contador.Q THEN
                estado := 0;
            END_IF;
        ELSE
            estado := 3; // Cambia a estado intermitente
        END_IF;
        
    3: // Estado intermitente
        luzV := FALSE;
        luzA := intermitente;
        luzR := FALSE;
        contador(IN := TRUE, PT := T#1S);
        IF contador.Q THEN
            intermitente := NOT intermitente; // Cambia el estado intermitente
            contador(IN := FALSE); // Reinicia el contador
            IF habilitado THEN
                estado := 0; // Vuelve al estado verde si se habilita nuevamente
            END_IF;
        END_IF;
        
END_CASE
```