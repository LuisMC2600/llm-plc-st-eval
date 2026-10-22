FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;    // Botón para giro en sentido horario
    btnRev : BOOL;    // Botón para giro en sentido antihorario
    btnParo : BOOL;   // Botón para parar el motor
END_VAR

VAR_OUTPUT
    fwd : BOOL;       // Salida para giro en sentido horario
    rev : BOOL;       // Salida para giro en sentido antihorario
END_VAR

VAR
    estado : INT;     // Estado actual del motor: 0 = Parado, 1 = Horario, -1 = Antihorario
END_VAR

// Inicialización
estado := 0;
fwd := FALSE;
rev := FALSE;

// Lógica de control
IF btnParo THEN
    // Si se presiona el botón de paro, detener el motor
    estado := 0;
    fwd := FALSE;
    rev := FALSE;
ELSIF btnFwd AND (estado = 0) THEN
    // Si se presiona el botón de avance y el motor está parado, girar en sentido horario
    estado := 1;
    fwd := TRUE;
    rev := FALSE;
ELSIF btnRev AND (estado = 0) THEN
    // Si se presiona el botón de retroceso y el motor está parado, girar en sentido antihorario
    estado := -1;
    fwd := FALSE;
    rev := TRUE;
END_IF;