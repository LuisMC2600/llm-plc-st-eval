```iec
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL; // Botón de paro
END_VAR

VAR_OUTPUT
    kM : BOOL; // Contactor principal
    kY : BOOL; // Contactor de estrella
    kD : BOOL; // Contactor de triángulo
END_VAR

VAR
    timerStar : TON; // Temporizador para el contacto de estrella
    timerDelta : TON; // Temporizador para el contacto de triángulo
    state : INT := 0; // Estado actual del programa
    deadTime : TON; // Temporizador para el tiempo muerto
END_VAR

// Inicialización de temporizadores
timerStar(IN := FALSE, PT := T#8S);
timerDelta(IN := FALSE, PT := T#100MS);
deadTime(IN := FALSE, PT := T#100MS);

// Lógica del programa
CASE state OF
    0: // Estado inicial
        IF btnMarcha THEN
            kM := TRUE;
            kY := TRUE;
            timerStar(IN := TRUE);
            state := 1;
        END_IF
        IF btnParo THEN
            kM := FALSE;
            kY := FALSE;
            kD := FALSE;
            state := 0;
        END_IF

    1: // Esperando para desactivar kY
        IF timerStar.Q THEN
            kY := FALSE;
            timerStar(IN := FALSE);
            deadTime(IN := TRUE);
            state := 2;
        END_IF
        IF btnParo THEN
            kM := FALSE;
            kY := FALSE;
            kD := FALSE;
            state := 0;
        END_IF

    2: // Tiempo muerto
        IF deadTime.Q THEN
            kD := TRUE;
            deadTime(IN := FALSE);
            state := 3;
        END_IF
        IF btnParo THEN
            kM := FALSE;
            kY := FALSE;
            kD := FALSE;
            state := 0;
        END_IF

    3: // Estado final
        IF btnParo THEN
            kM := FALSE;
            kY := FALSE;
            kD := FALSE;
            state := 0;
        END_IF
END_CASE
```

Este código implementa un arranque estrella-triángulo utilizando un FUNCTION_BLOCK en Structured Text (ST) conforme a IEC 61131-3. Las variables de entrada `btnMarcha` y `btnParo` controlan el inicio y el paro del proceso, respectivamente. Las salidas `kM`, `kY` y `kD` controlan los contactores principales y secundarios. Los temporizadores `timerStar`, `timerDelta` y `deadTime` gestionan los tiempos de espera y el tiempo muerto.