FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de inicio
    btnParo   : BOOL; // Botón de paro
END_VAR

VAR_OUTPUT
    kM : BOOL := FALSE; // Contactor principal
    kY : BOOL := FALSE; // Contactor estrella
    kD : BOOL := FALSE; // Contactor triángulo
END_VAR

VAR
    timerEstrella : TON; // Temporizador para el modo estrella
    timerMuerto   : TON; // Temporizador para el tiempo muerto
    estado        : INT := 0; // Estado del proceso
END_VAR

// Implementación del arranque estrella-triángulo
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
            timerEstrella(IN := TRUE, PT := T#8S); // Iniciar temporizador estrella
            estado := 1; // Cambiar al siguiente estado

        1: // Esperar a que termine el temporizador estrella
            IF timerEstrella.Q THEN
                kY := FALSE; // Desactivar contactor estrella
                timerMuerto(IN := TRUE, PT := T#100MS); // Iniciar temporizador de tiempo muerto
                estado := 2; // Cambiar al siguiente estado
            END_IF

        2: // Esperar a que termine el tiempo muerto
            IF timerMuerto.Q THEN
                kD := TRUE; // Activar contactor triángulo
                estado := 3; // Cambiar al estado final
            END_IF

        3: // Estado final, mantener contactor triángulo activado
            // No se realiza ninguna acción adicional
    END_CASE
ELSE
    // Si no se presiona ningún botón, mantener el estado actual
    timerEstrella(IN := FALSE); // Asegurarse de que el temporizador estrella esté desactivado
    timerMuerto(IN := FALSE); // Asegurarse de que el temporizador muerto esté desactivado
END_IF
END_FUNCTION_BLOCK