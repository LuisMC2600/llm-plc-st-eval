FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; // Sensor de presencia de pieza
    sensorAltura : BOOL; // Sensor de altura de pieza
END_VAR

VAR_OUTPUT
    banda : BOOL; // Salida de la banda transportadora
    piston : BOOL; // Salida del pistón para desviar piezas altas
    nAltas : INT; // Contador de piezas altas
    nBajas : INT; // Contador de piezas bajas
END_VAR

VAR
    timerDelay : TON; // Temporizador para el retardo de 2 segundos
    timerPiston : TON; // Temporizador para el activo del pistón durante 1 segundo
    piezaDetectada : BOOL; // Bandera para indicar si una pieza ha sido detectada
END_VAR

// Inicialización de temporizadores
timerDelay(IN := FALSE, PT := T#2S);
timerPiston(IN := FALSE, PT := T#1S);

// Banda transportadora siempre activa
banda := TRUE;

// Proceso principal
IF sensorPresencia THEN
    piezaDetectada := TRUE;
    timerDelay(IN := TRUE); // Iniciar el temporizador de retardo
ELSEIF piezaDetectada THEN
    IF timerDelay.Q THEN
        IF sensorAltura THEN
            nAltas := nAltas + 1; // Incrementar contador de piezas altas
            timerPiston(IN := TRUE); // Iniciar el temporizador del pistón
            piston := TRUE; // Activar el pistón
        ELSE
            nBajas := nBajas + 1; // Incrementar contador de piezas bajas
        END_IF
        piezaDetectada := FALSE; // Resetear la bandera de detección
    END_IF
END_IF

// Control del pistón
IF timerPiston.Q THEN
    timerPiston(IN := FALSE); // Detener el temporizador del pistón
    piston := FALSE; // Desactivar el pistón
END_IF
END_FUNCTION_BLOCK