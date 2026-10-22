PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; // Botón de inicio (contacto normalmente abierto)
    btnParo : BOOL;   // Botón de detención (contacto normalmente cerrado en la lógica)
END_VAR

VAR_OUTPUT
    motor : BOOL;     // Salida para el motor
    lampara : BOOL;   // Salida para la lámpara indicadora
END_VAR

VAR
    T1 : TON;         // Temporizador de retardo a la conexión
END_VAR

// Rama 1: Lógica de arranque y enclavamiento del motor
motor := (btnMarcha OR motor) AND NOT btnParo;

// Rama 2: Llamada al temporizador TON (10 segundos) activado por el motor
T1(IN := motor, PT := T#10S);

// Rama 3: Activación de la lámpara cuando el temporizador finaliza
lampara := T1.Q;

END_PROGRAM