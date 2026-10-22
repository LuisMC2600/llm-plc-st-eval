PROGRAM PRG_Conversion
VAR
    btnMarcha, btnParo : BOOL;  // Entradas
    motor, lampara : BOOL;      // Salidas
    T1 : TON;                   // Temporizador
END_VAR

// Rama 1: btnMarcha OR motor AND btnParo -> motor
motor := (btnMarcha OR motor) AND btnParo;

// Rama 2: motor -> T1 (10 segundos)
IF motor THEN
    T1(IN := TRUE, PT := T#10S);
ELSE
    T1(IN := FALSE);
END_IF;

// Rama 3: T1.Q -> lampara
lampara := T1.Q;