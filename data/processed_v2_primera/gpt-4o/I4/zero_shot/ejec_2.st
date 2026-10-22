FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL;   // Botón de paro
END_VAR

VAR_OUTPUT
    kM : BOOL := FALSE; // Contactor principal
    kY : BOOL := FALSE; // Contactor estrella
    kD : BOOL := FALSE; // Contactor triángulo
END_VAR

VAR
    estado : INT := 0; // Estado del proceso
    timerEstrella : TON; // Temporizador para el tiempo en estrella
    timerMuerto : TON;   // Temporizador para el tiempo muerto
END_VAR

// Inicialización de temporizadores
timerEstrella(IN := FALSE, PT := T#8S);
timerMuerto(IN := FALSE, PT := T#100MS);

IF btnParo THEN
    // Si se presiona el botón de paro, desactivar todos los contactores y reiniciar el estado
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0: // Estado inicial
            kM := TRUE; // Activar contactor principal
            kY := TRUE; // Activar contactor estrella
            timerEstrella(IN := TRUE); // Iniciar temporizador de estrella
            estado := 1; // Avanzar al siguiente estado

        1: // Estado de espera en estrella
            IF timerEstrella.Q THEN
                kY := FALSE; // Desactivar contactor estrella
                timerEstrella(IN := FALSE); // Reiniciar temporizador de estrella
                timerMuerto(IN := TRUE); // Iniciar temporizador de tiempo muerto
                estado := 2; // Avanzar al siguiente estado
            END_IF

        2: // Estado de tiempo muerto
            IF timerMuerto.Q THEN
                timerMuerto(IN := FALSE); // Reiniciar temporizador de tiempo muerto
                kD := TRUE; // Activar contactor triángulo
                estado := 3; // Avanzar al siguiente estado
            END_IF

        3: // Estado de operación en triángulo
            // Mantenerse en este estado hasta que se presione el botón de paro
            // No se requiere acción adicional
    END_CASE
ELSE
    // Si no se presiona ningún botón, mantener el estado actual
    // No se requiere acción adicional
END_IF
END_FUNCTION_BLOCK