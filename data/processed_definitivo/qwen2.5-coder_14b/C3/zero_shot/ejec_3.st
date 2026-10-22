PROGRAM PRG_Conversion
VAR
    btnMarcha, btnParo : BOOL;  // Entradas
    motor, lampara : BOOL;      // Salidas
    T1 : TON;                   // Temporizador de 10 segundos
END_VAR

// Rama 1: btnMarcha y motor en paralelo, en serie con btnParo, alimentan motor
motor := (btnMarcha OR motor) AND btnParo;

// Rama 2: motor alimenta el temporizador T1 con tiempo preestablecido de 10 segundos
IF motor THEN
    T1(IN := TRUE, PT := T#10S);
ELSE
    T1(IN := FALSE);
END_IF;

// Rama 3: T1.Q alimenta la bobina lampara
lampara := T1.Q;