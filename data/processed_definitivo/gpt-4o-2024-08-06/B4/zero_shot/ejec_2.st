FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;   // Botón para giro en sentido horario
    btnRev : BOOL;   // Botón para giro en sentido antihorario
    btnParo : BOOL;  // Botón para detener el motor
END_VAR

VAR_OUTPUT
    fwd : BOOL;      // Salida para giro en sentido horario
    rev : BOOL;      // Salida para giro en sentido antihorario
END_VAR

VAR
    estado : INT;    // Estado actual del motor: 0 = Paro, 1 = Fwd, 2 = Rev
END_VAR

// Inicialización del estado
estado := 0;

// Lógica de control del motor
IF btnParo THEN
    // Si se presiona el botón de paro, detener el motor
    estado := 0;
ELSIF btnFwd AND (estado = 0) THEN
    // Si se presiona el botón de avance y el motor está parado, girar en sentido horario
    estado := 1;
ELSIF btnRev AND (estado = 0) THEN
    // Si se presiona el botón de retroceso y el motor está parado, girar en sentido antihorario
    estado := 2;
END_IF

// Actualización de las salidas según el estado
CASE estado OF
    0: // Estado de paro
        fwd := FALSE;
        rev := FALSE;
    1: // Estado de giro en sentido horario
        fwd := TRUE;
        rev := FALSE;
    2: // Estado de giro en sentido antihorario
        fwd := FALSE;
        rev := TRUE;
END_CASE

END_FUNCTION_BLOCK