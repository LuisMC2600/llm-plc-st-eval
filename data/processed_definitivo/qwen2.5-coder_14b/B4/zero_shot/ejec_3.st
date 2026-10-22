FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;  // Botón para girar en sentido horario
    btnRev : BOOL;  // Botón para girar en sentido antihorario
    btnParo : BOOL; // Botón para parar el motor
END_VAR

VAR_OUTPUT
    fwd : BOOL;    // Salida para giro horario
    rev : BOOL;    // Salida para giro antihorario
END_VAR

VAR
    estado : INT := 0; // Estado actual del sistema (0: Parado, 1: Giro horario, 2: Giro antihorario)
END_VAR

// Transiciones de estado
CASE estado OF
    0: // Estado Parado
        IF btnFwd THEN
            estado := 1; // Cambia a giro horario
        ELSIF btnRev THEN
            estado := 2; // Cambia a giro antihorario
        END_IF

    1: // Estado Giro Horario
        IF btnParo THEN
            estado := 0; // Cambia a parado
        ELSIF btnRev THEN
            estado := 2; // Cambia a giro antihorario
        END_IF

    2: // Estado Giro Antihorario
        IF btnParo THEN
            estado := 0; // Cambia a parado
        ELSIF btnFwd THEN
            estado := 1; // Cambia a giro horario
        END_IF
END_CASE

// Asignación de salidas según el estado
CASE estado OF
    0:
        fwd := FALSE;
        rev := FALSE;
    1:
        fwd := TRUE;
        rev := FALSE;
    2:
        fwd := FALSE;
        rev := TRUE;
END_CASE
END_FUNCTION_BLOCK