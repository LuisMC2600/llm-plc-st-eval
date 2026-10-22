```pascal
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
    estado : INT;    // Estado del motor: 0 = Paro, 1 = Horario, 2 = Antihorario
END_VAR

// Inicialización de salidas
fwd := FALSE;
rev := FALSE;

// Lógica de control del motor
IF btnParo THEN
    estado := 0; // Cambiar a estado de paro
ELSIF btnFwd AND (estado = 0) THEN
    estado := 1; // Cambiar a estado de giro horario
ELSIF btnRev AND (estado = 0) THEN
    estado := 2; // Cambiar a estado de giro antihorario
END_IF

// Actualización de salidas según el estado
CASE estado OF
    0: // Paro
        fwd := FALSE;
        rev := FALSE;
    1: // Giro horario
        fwd := TRUE;
        rev := FALSE;
    2: // Giro antihorario
        fwd := FALSE;
        rev := TRUE;
END_CASE
END_FUNCTION_BLOCK
```

Este código implementa la lógica de inversión de giro de un motor, asegurando que las salidas `fwd` y `rev` nunca estén activas al mismo tiempo y que el motor pase por el estado de paro antes de cambiar de dirección.