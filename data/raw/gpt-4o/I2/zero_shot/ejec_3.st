```pascal
FUNCTION_BLOCK FB_Llenado
VAR
    // Variables de entrada
    nivelAlto : BOOL;    // Sensor de nivel alto
    nivelBajo : BOOL;    // Sensor de nivel bajo
    btnInicio : BOOL;    // Botón de inicio
    btnParo   : BOOL;    // Botón de paro

    // Variables de salida
    vLlenado    : BOOL;  // Válvula de llenado
    motorMezcla : BOOL;  // Motor de mezcla
    vDescarga   : BOOL;  // Válvula de descarga

    // Variables internas
    estado      : INT;   // Estado del proceso
    timerMezcla : TON;   // Temporizador para el motor de mezcla
END_VAR

// Inicialización del temporizador
timerMezcla(IN := FALSE, PT := T#60S);

// Lógica del proceso de llenado por etapas
IF btnParo THEN
    // Si se presiona el botón de paro, llevar todo a estado seguro
    estado := 0;
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
ELSIF btnInicio THEN
    CASE estado OF
        0: // Estado de reposo
            IF btnInicio THEN
                estado := 1; // Iniciar proceso de llenado
            END_IF;
        
        1: // Estado de llenado
            vLlenado := TRUE;
            IF nivelAlto THEN
                vLlenado := FALSE;
                estado := 2; // Pasar al estado de mezcla
            END_IF;
        
        2: // Estado de mezcla
            motorMezcla := TRUE;
            timerMezcla(IN := TRUE);
            IF timerMezcla.Q THEN
                motorMezcla := FALSE;
                timerMezcla(IN := FALSE);
                estado := 3; // Pasar al estado de descarga
            END_IF;
        
        3: // Estado de descarga
            vDescarga := TRUE;
            IF nivelBajo THEN
                vDescarga := FALSE;
                estado := 0; // Volver al estado de reposo
            END_IF;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK
```

Este código implementa un proceso de llenado por etapas en un bloque de función llamado `FB_Llenado`, utilizando el lenguaje Structured Text (ST) conforme al estándar IEC 61131-3. El proceso se controla mediante un estado interno y responde a los botones de inicio y paro, así como a los sensores de nivel.