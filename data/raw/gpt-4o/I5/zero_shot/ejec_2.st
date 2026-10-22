```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL;  // Sensor que detecta la presencia de una pieza
    sensorAltura : BOOL;     // Sensor que detecta si la pieza es alta
END_VAR

VAR_OUTPUT
    banda : BOOL;            // Salida para activar la banda transportadora
    piston : BOOL;           // Salida para activar el pistón desviador
    nAltas : INT;            // Contador de piezas altas
    nBajas : INT;            // Contador de piezas bajas
END_VAR

VAR
    estado : INT;            // Estado del sistema
    temporizadorDesvio : TON; // Temporizador para el retraso de 2 segundos
    temporizadorPiston : TON; // Temporizador para la duración de 1 segundo del pistón
    piezaAltaDetectada : BOOL; // Indica si se detectó una pieza alta
END_VAR

// Inicialización
banda := TRUE; // La banda siempre está activa

// Máquina de estados para el control del pistón y conteo de piezas
CASE estado OF
    0: // Estado inicial, esperando detección de pieza
        IF sensorPresencia THEN
            IF sensorAltura THEN
                piezaAltaDetectada := TRUE;
                temporizadorDesvio(IN := TRUE, PT := T#2S);
            ELSE
                nBajas := nBajas + 1;
            END_IF;
            estado := 1;
        END_IF;

    1: // Esperando el tiempo de retraso para activar el pistón
        temporizadorDesvio(IN := sensorPresencia AND piezaAltaDetectada);
        IF temporizadorDesvio.Q THEN
            piston := TRUE;
            temporizadorPiston(IN := TRUE, PT := T#1S);
            estado := 2;
        END_IF;

    2: // Activando el pistón durante 1 segundo
        temporizadorPiston(IN := TRUE);
        IF temporizadorPiston.Q THEN
            piston := FALSE;
            nAltas := nAltas + 1;
            piezaAltaDetectada := FALSE;
            estado := 0;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK
```

Este código implementa un bloque de función `FB_Clasificadora` que controla una banda transportadora clasificadora. La banda siempre está activa, y el sistema utiliza una máquina de estados para gestionar el desvío de piezas altas y el conteo de piezas altas y bajas. Los temporizadores se utilizan para manejar el retraso y la duración del pistón.