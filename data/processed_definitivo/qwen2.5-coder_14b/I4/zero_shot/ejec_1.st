FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL;   // Botón de paro
END_VAR

VAR_OUTPUT
    kM : BOOL;       // Contactor principal
    kY : BOOL;       // Contactor de estrella
    kD : BOOL;       // Contactor de triángulo
END_VAR

VAR
    timerEstrella : TON; // Temporizador para el contacto de estrella
    timerMuerto : TON;   // Temporizador para el tiempo muerto
    estado : INT;       // Variable de estado del arranque
END_VAR

// Inicialización de temporizadores
timerEstrella(IN := FALSE, PT := T#8S);
timerMuerto(IN := FALSE, PT := T#100MS);

// Máquina de estados
CASE estado OF
    0: // Estado inicial
        IF btnMarcha THEN
            kM := TRUE; // Activar el contactor principal
            kY := TRUE; // Activar el contactor de estrella
            timerEstrella(IN := TRUE); // Iniciar temporizador para el contacto de estrella
            estado := 1; // Transición al estado 1
        END_IF

    1: // Esperando el fin del temporizador de estrella
        IF timerEstrella.Q THEN
            kY := FALSE; // Desactivar el contactor de estrella
            timerMuerto(IN := TRUE); // Iniciar temporizador para el tiempo muerto
            estado := 2; // Transición al estado 2
        END_IF

    2: // Esperando el fin del temporizador de tiempo muerto
        IF timerMuerto.Q THEN
            kD := TRUE; // Activar el contactor de triángulo
            estado := 3; // Transición al estado 3
        END_IF

    3: // Estado final
        // Mantener los contactores activados según el estado actual
        IF btnParo THEN
            kM := FALSE; // Desactivar el contactor principal
            kY := FALSE; // Desactivar el contactor de estrella
            kD := FALSE; // Desactivar el contactor de triángulo
            estado := 0; // Reiniciar a estado inicial
        END_IF
END_CASE