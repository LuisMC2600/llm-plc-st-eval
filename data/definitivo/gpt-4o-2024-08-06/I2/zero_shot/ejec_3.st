```pascal
FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto : BOOL;    // Sensor de nivel alto
    nivelBajo : BOOL;    // Sensor de nivel bajo
    btnInicio : BOOL;    // Botón de inicio
    btnParo   : BOOL;    // Botón de paro
END_VAR

VAR_OUTPUT
    vLlenado   : BOOL;   // Válvula de llenado
    motorMezcla: BOOL;   // Motor de mezcla
    vDescarga  : BOOL;   // Válvula de descarga
END_VAR

VAR
    estado     : INT;    // Estado del proceso
    timerMezcla: TON;    // Temporizador para el motor de mezcla
END_VAR

// Estados del proceso
// 0: Reposo
// 1: Llenado
// 2: Mezcla
// 3: Descarga

// Inicialización del bloque
IF NOT btnInicio THEN
    estado := 0;
END_IF

// Lógica de control del proceso
CASE estado OF
    0: // Reposo
        vLlenado := FALSE;
        motorMezcla := FALSE;
        vDescarga := FALSE;
        IF btnInicio THEN
            estado := 1;
        END_IF

    1: // Llenado
        vLlenado := TRUE;
        IF nivelAlto THEN
            vLlenado := FALSE;
            estado := 2;
            timerMezcla(IN := TRUE, PT := T#60S);
        END_IF

    2: // Mezcla
        motorMezcla := TRUE;
        timerMezcla(IN := TRUE);
        IF timerMezcla.Q THEN
            motorMezcla := FALSE;
            estado := 3;
        END_IF

    3: // Descarga
        vDescarga := TRUE;
        IF nivelBajo THEN
            vDescarga := FALSE;
            estado := 0;
        END_IF
END_CASE

// Lógica de paro de emergencia
IF btnParo THEN
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    estado := 0;
END_IF

END_FUNCTION_BLOCK
```

Este código implementa un proceso de llenado por etapas utilizando el lenguaje Structured Text (ST) conforme al estándar IEC 61131-3. El proceso se controla mediante un bloque de función `FB_Llenado` que gestiona las entradas y salidas necesarias para el funcionamiento del sistema.