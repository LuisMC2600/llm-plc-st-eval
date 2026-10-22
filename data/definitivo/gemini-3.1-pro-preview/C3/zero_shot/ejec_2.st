```iecst
PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; // Contacto normalmente abierto para iniciar
    btnParo : BOOL;   // Contacto normalmente cerrado para detener
END_VAR

VAR_OUTPUT
    motor : BOOL;     // Bobina del motor
    lampara : BOOL;   // Bobina de la lámpara indicadora
END_VAR

VAR
    T1 : TON;         // Temporizador a la conexión (Timer On Delay)
END_VAR

// Rama 1: Lógica de enclavamiento (arranque y paro) para el motor
motor := (btnMarcha OR motor) AND NOT btnParo;

// Rama 2: Llamada al temporizador T1, se activa cuando el motor está encendido
T1(IN := motor, PT := T#10S);

// Rama 3: La lámpara se enciende cuando el temporizador T1 termina su conteo
lampara := T1.Q;

END_PROGRAM
```