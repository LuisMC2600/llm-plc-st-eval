FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;    // Botón para giro en sentido horario
    btnRev : BOOL;    // Botón para giro en sentido antihorario
    btnParo : BOOL;   // Botón de paro
END_VAR

VAR_OUTPUT
    fwd : BOOL := FALSE;  // Salida para giro en sentido horario
    rev : BOOL := FALSE;  // Salida para giro en sentido antihorario
END_VAR

VAR
    estado : INT := 0;    // Estado del motor: 0 = Parado, 1 = Horario, 2 = Antihorario
END_VAR

// Lógica de control del motor
IF btnParo THEN
    // Si se presiona el botón de paro, detener el motor
    fwd := FALSE;
    rev := FALSE;
    estado := 0;
ELSIF btnFwd AND (estado = 0) THEN
    // Si se presiona el botón de giro horario y el motor está parado
    fwd := TRUE;
    rev := FALSE;
    estado := 1;
ELSIF btnRev AND (estado = 0) THEN
    // Si se presiona el botón de giro antihorario y el motor está parado
    fwd := FALSE;
    rev := TRUE;
    estado := 2;
END_IF
END_FUNCTION_BLOCK