```pascal
PROGRAM PRG_Conversion
VAR
    // Entradas
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL;   // Botón de paro

    // Salidas
    motor : BOOL;     // Bobina del motor
    lampara : BOOL;   // Bobina de la lámpara

    // Temporizador
    T1 : TON;         // Temporizador TON
END_VAR

// Lógica de control
motor := (btnMarcha OR motor) AND NOT btnParo;

// Configuración y ejecución del temporizador
T1(IN := motor, PT := T#10S);

// Control de la lámpara
lampara := T1.Q;
```