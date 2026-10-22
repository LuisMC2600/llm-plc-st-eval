FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; // Sensor que detecta la presencia de una pieza
    sensorAltura : BOOL;    // Sensor que detecta si la pieza es alta
END_VAR

VAR_OUTPUT
    banda : BOOL;   // Control de la banda transportadora
    piston : BOOL;  // Control del pistón desviador
    nAltas : INT;   // Contador de piezas altas
    nBajas : INT;   // Contador de piezas bajas
END_VAR

VAR
    estado : INT;           // Estado del proceso
    temporizador : TON;     // Temporizador para el retraso del pistón
    activarPiston : BOOL;   // Señal para activar el pistón
END_VAR

// Inicialización
banda := TRUE; // La banda siempre está activa

// Máquina de estados para el control del proceso
CASE estado OF
    0: // Estado inicial
        IF sensorPresencia THEN
            IF sensorAltura THEN
                // La pieza es alta, iniciar temporizador para el pistón
                temporizador(IN := TRUE, PT := T#2S);
                estado := 1;
            ELSE
                // La pieza es baja, incrementar contador
                nBajas := nBajas + 1;
                estado := 0; // Volver al estado inicial
            END_IF
        END_IF

    1: // Esperar 2 segundos para activar el pistón
        temporizador(IN := TRUE, PT := T#2S);
        IF temporizador.Q THEN
            // Activar el pistón por 1 segundo
            activarPiston := TRUE;
            temporizador(IN := FALSE);
            temporizador(IN := TRUE, PT := T#1S);
            estado := 2;
        END_IF

    2: // Mantener el pistón activado por 1 segundo
        piston := activarPiston;
        IF temporizador.Q THEN
            // Desactivar el pistón y actualizar contador
            activarPiston := FALSE;
            piston := FALSE;
            nAltas := nAltas + 1;
            estado := 0; // Volver al estado inicial
        END_IF
END_CASE
END_FUNCTION_BLOCK