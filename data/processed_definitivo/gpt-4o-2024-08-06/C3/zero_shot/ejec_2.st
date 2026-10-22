PROGRAM PRG_Conversion
VAR
    btnMarcha : BOOL;   // Botón de marcha (entrada)
    btnParo : BOOL;     // Botón de paro (entrada)
    motor : BOOL;       // Estado del motor (salida)
    lampara : BOOL;     // Estado de la lámpara (salida)
    T1 : TON;           // Temporizador TON
END_VAR

// Lógica de control del motor
IF (btnMarcha OR motor) AND NOT btnParo THEN
    motor := TRUE;
ELSE
    motor := FALSE;
END_IF;

// Configuración y ejecución del temporizador TON
T1(IN := motor, PT := T#10S);

// Control de la lámpara basado en el temporizador
lampara := T1.Q;