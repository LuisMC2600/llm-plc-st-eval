```pascal
FUNCTION_BLOCK FB_Llenado
VAR
    // Entradas
    nivelAlto : BOOL;   // Sensor de nivel alto
    nivelBajo : BOOL;   // Sensor de nivel bajo
    btnInicio : BOOL;   // Botón de inicio
    btnParo   : BOOL;   // Botón de paro

    // Salidas
    vLlenado   : BOOL;  // Válvula de llenado
    motorMezcla: BOOL;  // Motor de mezcla
    vDescarga  : BOOL;  // Válvula de descarga

    // Variables internas
    estadoProceso : INT;        // Estado del proceso
    timerMezcla   : TON;        // Temporizador para el motor de mezcla
END_VAR

// Inicialización
IF btnParo THEN
    // Si se presiona el botón de paro, reiniciar el proceso
    estadoProceso := 0;
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
ELSE
    CASE estadoProceso OF
        0: // Estado de reposo
            IF btnInicio THEN
                estadoProceso := 1; // Ir al estado de llenado
            END_IF;

        1: // Estado de llenado
            vLlenado := TRUE;
            IF nivelAlto THEN
                vLlenado := FALSE;
                estadoProceso := 2; // Ir al estado de mezcla
                timerMezcla(IN := TRUE, PT := T#60S); // Iniciar temporizador de mezcla
            END_IF;

        2: // Estado de mezcla
            motorMezcla := TRUE;
            timerMezcla(IN := TRUE);
            IF timerMezcla.Q THEN
                motorMezcla := FALSE;
                estadoProceso := 3; // Ir al estado de descarga
            END_IF;

        3: // Estado de descarga
            vDescarga := TRUE;
            IF nivelBajo THEN
                vDescarga := FALSE;
                estadoProceso := 0; // Volver al estado de reposo
            END_IF;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK
```

Este código implementa un proceso de llenado por etapas en un bloque de función llamado `FB_Llenado`. El proceso se controla mediante un estado interno (`estadoProceso`) y responde a las entradas de los sensores y botones. El temporizador `timerMezcla` se utiliza para controlar el tiempo de operación del motor de mezcla.