FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; // Sensor que detecta el paso de una pieza
    sensorAltura : BOOL;    // Sensor que detecta si la pieza es alta
END_VAR

VAR_OUTPUT
    banda : BOOL;           // Salida para activar la banda transportadora
    piston : BOOL;          // Salida para activar el pistón desviador
    nAltas : INT := 0;      // Contador de piezas altas
    nBajas : INT := 0;      // Contador de piezas bajas
END_VAR

VAR
    trigPresencia : R_TRIG; // Detector de flanco de subida para el sensor de presencia
    esperaPiston : BOOL;    // Marca de memoria para iniciar el retardo del pistón
    tonRetardo : TON;       // Temporizador de retardo (llegada al desviador)
    tpPiston : TP;          // Temporizador de pulso (duración de activación del pistón)
END_VAR

// 1. La banda funciona continuamente
banda := TRUE;

// 2. Detección del paso de una pieza (flanco de subida)
trigPresencia(CLK := sensorPresencia);

IF trigPresencia.Q THEN
    IF sensorAltura THEN
        // Es una pieza alta
        nAltas := nAltas + 1;
        esperaPiston := TRUE; // Se activa la bandera para iniciar el retardo
    ELSE
        // Es una pieza baja
        nBajas := nBajas + 1;
    END_IF;
END_IF;

// 3. Temporizador de retardo: espera 2 segundos a que la pieza llegue al pistón
tonRetardo(IN := esperaPiston, PT := T#2S);

// Al cumplirse los 2 segundos, se apaga la marca de espera
IF tonRetardo.Q THEN
    esperaPiston := FALSE; 
END_IF;

// 4. Temporizador de pulso: activa el pistón durante 1 segundo
// Se dispara con el flanco de subida de tonRetardo.Q
tpPiston(IN := tonRetardo.Q, PT := T#1S);

// 5. Asignación de la salida física del pistón
piston := tpPiston.Q;

END_FUNCTION_BLOCK