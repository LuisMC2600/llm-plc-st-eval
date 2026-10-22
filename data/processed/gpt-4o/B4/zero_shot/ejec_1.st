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
    estado : INT;    // Estado actual del motor
END_VAR

// Estados posibles
// 0: Parado
// 1: Girando en sentido horario
// 2: Girando en sentido antihorario

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
    1: // Girando en sentido horario
        fwd := TRUE;
        rev := FALSE;
    2: // Girando en sentido antihorario
        fwd := FALSE;
        rev := TRUE;
END_CASE

END_FUNCTION_BLOCK