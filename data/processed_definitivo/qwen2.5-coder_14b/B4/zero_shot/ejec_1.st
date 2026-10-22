FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;  // Botón para girar en sentido horario
    btnRev : BOOL;  // Botón para girar en sentido antihorario
    btnParo : BOOL; // Botón para parar el motor
END_VAR

VAR_OUTPUT
    fwd : BOOL;    // Salida para girar en sentido horario
    rev : BOOL;    // Salida para girar en sentido antihorario
END_VAR

VAR
    estado : INT := 0; // Estado actual del sistema (0: Parado, 1: Giro horario, 2: Giro antihorario)
END_VAR

// Máquina de estados
CASE estado OF
    0: // Estado Parado
        fwd := FALSE;
        rev := FALSE;
        IF btnFwd THEN
            estado := 1; // Cambia a giro horario
        ELSIF btnRev THEN
            estado := 2; // Cambia a giro antihorario
        END_IF

    1: // Estado Giro Horario
        fwd := TRUE;
        rev := FALSE;
        IF btnParo THEN
            estado := 0; // Cambia a parado
        ELSIF btnRev THEN
            estado := 2; // Cambia a giro antihorario
        END_IF

    2: // Estado Giro Antihorario
        fwd := FALSE;
        rev := TRUE;
        IF btnParo THEN
            estado := 0; // Cambia a parado
        ELSIF btnFwd THEN
            estado := 1; // Cambia a giro horario
        END_IF
END_CASE