FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;   // Botón para giro en sentido horario
    btnRev : BOOL;   // Botón para giro en sentido antihorario
    btnParo : BOOL;  // Botón de paro
END_VAR

VAR_OUTPUT
    fwd : BOOL;      // Salida para giro en sentido horario
    rev : BOOL;      // Salida para giro en sentido antihorario
END_VAR

VAR
    estado : INT;    // Estado del motor: 0 = Parado, 1 = Horario, 2 = Antihorario
END_VAR

// Inicialización de salidas
fwd := FALSE;
rev := FALSE;

// Lógica de control
IF btnParo THEN
    // Si se presiona el botón de paro, el motor se detiene
    estado := 0;
ELSIF btnFwd AND (estado = 0) THEN
    // Si se presiona el botón de giro horario y el motor está parado
    estado := 1;
ELSIF btnRev AND (estado = 0) THEN
    // Si se presiona el botón de giro antihorario y el motor está parado
    estado := 2;
END_IF

// Actualización de salidas según el estado
CASE estado OF
    0: // Parado
        fwd := FALSE;
        rev := FALSE;
    1: // Giro horario
        fwd := TRUE;
        rev := FALSE;
    2: // Giro antihorario
        fwd := FALSE;
        rev := TRUE;
END_CASE;

END_FUNCTION_BLOCK