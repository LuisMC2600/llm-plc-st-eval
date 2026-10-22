PROGRAM PRG_Conversion
VAR
    // Declaración de variables de entrada
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL;   // Botón de paro

    // Declaración de variables de salida
    motor : BOOL;     // Estado del motor
    lampara : BOOL;   // Estado de la lámpara

    // Declaración del temporizador TON
    T1 : TON;         // Temporizador TON
END_VAR

// Lógica de control
// Rama 1: Control del motor
IF (btnMarcha OR motor) AND NOT btnParo THEN
    motor := TRUE;
ELSE
    motor := FALSE;
END_IF;

// Rama 2: Activación del temporizador TON
T1(IN := motor, PT := T#10S);

// Rama 3: Control de la lámpara
lampara := T1.Q;