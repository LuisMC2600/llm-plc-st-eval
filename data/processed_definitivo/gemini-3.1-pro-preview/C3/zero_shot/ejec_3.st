PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; // Contacto normalmente abierto para arranque
    btnParo : BOOL;   // Contacto normalmente cerrado para detención
END_VAR

VAR_OUTPUT
    motor : BOOL;     // Bobina del motor
    lampara : BOOL;   // Bobina de la lámpara
END_VAR

VAR
    T1 : TON;         // Temporizador de retardo a la conexión
END_VAR

// Rama 1: Circuito de auto-retención (enclavamiento) del motor
motor := (btnMarcha OR motor) AND NOT btnParo;

// Rama 2: El motor activa el temporizador TON con un preset de 10 segundos
T1(IN := motor, PT := T#10S);

// Rama 3: La salida del temporizador enciende la lámpara
lampara := T1.Q;

END_PROGRAM