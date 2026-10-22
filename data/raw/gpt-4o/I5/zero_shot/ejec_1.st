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
    temporizadorDesvio : TON; // Temporizador para el retraso del pistón
    temporizadorPiston : TON; // Temporizador para la duración del pistón
END_VAR

// Inicialización
banda := TRUE; // La banda siempre está activa

// Máquina de estados para el control del pistón y conteo
CASE estado OF
    0: // Estado de espera
        IF sensorPresencia THEN
            IF sensorAltura THEN
                // La pieza es alta, iniciar temporizador de desvío
                temporizadorDesvio(IN := TRUE, PT := T#2S);
                estado := 1;
            ELSE
                // La pieza es baja, incrementar contador de bajas
                nBajas := nBajas + 1;
            END_IF;
        END_IF;

    1: // Esperando el tiempo de desvío
        IF temporizadorDesvio.Q THEN
            // Activar pistón y temporizador de pistón
            piston := TRUE;
            temporizadorPiston(IN := TRUE, PT := T#1S);
            estado := 2;
        END_IF;

    2: // Pistón activado
        IF temporizadorPiston.Q THEN
            // Desactivar pistón y resetear temporizadores
            piston := FALSE;
            temporizadorDesvio(IN := FALSE);
            temporizadorPiston(IN := FALSE);
            // Incrementar contador de altas
            nAltas := nAltas + 1;
            estado := 0;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK
```

Este código implementa un bloque de función `FB_Clasificadora` que controla una banda transportadora y clasifica piezas en altas y bajas. Utiliza una máquina de estados para gestionar el tiempo de activación del pistón y cuenta las piezas clasificadas.