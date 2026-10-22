```pascal
FUNCTION_BLOCK FB_Llenado
VAR
    // Entradas
    nivelAlto : BOOL;    // Sensor de nivel alto
    nivelBajo : BOOL;    // Sensor de nivel bajo
    btnInicio : BOOL;    // Botón de inicio
    btnParo : BOOL;      // Botón de paro

    // Salidas
    vLlenado : BOOL;     // Válvula de llenado
    motorMezcla : BOOL;  // Motor de mezcla
    vDescarga : BOOL;    // Válvula de descarga

    // Variables internas
    estado : INT;        // Estado del proceso
    timerMezcla : TON;   // Temporizador para el motor de mezcla
END_VAR

// Inicialización del bloque de función
IF NOT btnParo THEN
    CASE estado OF
        0: // Estado de reposo
            vLlenado := FALSE;
            motorMezcla := FALSE;
            vDescarga := FALSE;
            IF btnInicio THEN
                estado := 1; // Ir al estado de llenado
            END_IF;

        1: // Estado de llenado
            vLlenado := TRUE;
            IF nivelAlto THEN
                vLlenado := FALSE;
                estado := 2; // Ir al estado de mezcla
                timerMezcla(IN := TRUE, PT := T#60S);
            END_IF;

        2: // Estado de mezcla
            motorMezcla := TRUE;
            timerMezcla(IN := TRUE);
            IF timerMezcla.Q THEN
                motorMezcla := FALSE;
                estado := 3; // Ir al estado de descarga
            END_IF;

        3: // Estado de descarga
            vDescarga := TRUE;
            IF nivelBajo THEN
                vDescarga := FALSE;
                estado := 0; // Volver al estado de reposo
            END_IF;
    END_CASE;
ELSE
    // Estado seguro en caso de paro
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    estado := 0; // Volver al estado de reposo
    timerMezcla(IN := FALSE);
END_IF;
END_FUNCTION_BLOCK
```

Este código implementa un proceso de llenado por etapas utilizando un bloque de función en Structured Text (ST) conforme al estándar IEC 61131-3. El proceso se controla mediante un autómata de estados que responde a las entradas de los sensores y botones, y controla las salidas correspondientes.