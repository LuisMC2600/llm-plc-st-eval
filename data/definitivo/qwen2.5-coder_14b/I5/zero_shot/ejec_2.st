```iec
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; // Sensor de presencia de pieza
    sensorAltura : BOOL;    // Sensor de altura de pieza
END_VAR

VAR_OUTPUT
    banda : BOOL;          // Salida para activar la banda
    piston : BOOL;         // Salida para activar el pistón
    nAltas : INT;          // Contador de piezas altas
    nBajas : INT;          // Contador de piezas bajas
END_VAR

VAR
    timer1 : TON;           // Timer para esperar 2 segundos
    timer2 : TON;           // Timer para activar el pistón durante 1 segundo
    piezaDetectada : BOOL;  // Bandera para detectar pieza
END_VAR

// Inicialización de variables
IF NOT piezaDetectada THEN
    timer1(IN := FALSE);
    timer2(IN := FALSE);
    piston := FALSE;
END_IF

// Detectar pieza
IF sensorPresencia AND NOT piezaDetectada THEN
    piezaDetectada := TRUE;
    timer1(IN := TRUE);
    timer1(PTR := T#2S);
END_IF

// Esperar 2 segundos antes de evaluar la altura
IF timer1.Q THEN
    timer1(IN := FALSE);
    IF sensorAltura THEN
        nAltas := nAltas + 1;
        timer2(IN := TRUE);
        timer2(PTR := T#1S);
        piston := TRUE;
    ELSE
        nBajas := nBajas + 1;
    END_IF
END_IF

// Activar el pistón durante 1 segundo
IF timer2.Q THEN
    timer2(IN := FALSE);
    piston := FALSE;
END_IF

// Mantener la banda activa
banda := TRUE;

// Reiniciar la bandera de detección de pieza
IF sensorPresencia = FALSE THEN
    piezaDetectada := FALSE;
END_IF
END_FUNCTION_BLOCK
```