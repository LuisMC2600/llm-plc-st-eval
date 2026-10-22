FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; // Sensor que detecta la presencia de una pieza
    sensorAltura : BOOL;    // Sensor que detecta si la pieza es alta
END_VAR

VAR_OUTPUT
    banda : BOOL := TRUE;   // Salida que activa la banda transportadora
    piston : BOOL := FALSE; // Salida que activa el pistón desviador
    nAltas : INT := 0;      // Contador de piezas altas
    nBajas : INT := 0;      // Contador de piezas bajas
END_VAR

VAR
    estadoAnteriorPresencia : BOOL := FALSE; // Estado anterior del sensor de presencia
    temporizadorRetraso : TON;              // Temporizador para el retraso de 2 segundos
    temporizadorPiston : TON;               // Temporizador para la duración de 1 segundo del pistón
    activarPiston : BOOL := FALSE;          // Bandera para activar el pistón
END_VAR

// Inicialización de los temporizadores
temporizadorRetraso(IN := FALSE, PT := T#2S);
temporizadorPiston(IN := FALSE, PT := T#1S);

// Detectar flanco de subida del sensor de presencia
IF (sensorPresencia AND NOT estadoAnteriorPresencia) THEN
    IF sensorAltura THEN
        // Iniciar temporizador de retraso para piezas altas
        temporizadorRetraso(IN := TRUE);
        activarPiston := TRUE;
    ELSE
        // Incrementar contador de piezas bajas
        nBajas := nBajas + 1;
    END_IF;
END_IF;

// Actualizar estado anterior del sensor de presencia
estadoAnteriorPresencia := sensorPresencia;

// Control del pistón
IF activarPiston THEN
    // Si el temporizador de retraso ha terminado, iniciar temporizador del pistón
    IF temporizadorRetraso.Q THEN
        temporizadorPiston(IN := TRUE);
        temporizadorRetraso(IN := FALSE);
    END_IF;

    // Activar el pistón durante 1 segundo
    IF temporizadorPiston.Q THEN
        piston := FALSE;
        temporizadorPiston(IN := FALSE);
        activarPiston := FALSE;
        nAltas := nAltas + 1; // Incrementar contador de piezas altas
    ELSE
        piston := TRUE;
    END_IF;
ELSE
    piston := FALSE;
END_IF;

banda := TRUE; // La banda siempre está activa
END_FUNCTION_BLOCK