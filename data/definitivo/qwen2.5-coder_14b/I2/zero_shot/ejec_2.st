```pascal
FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto : BOOL;  // Nivel alto detectado
    nivelBajo : BOOL;  // Nivel bajo detectado
    btnInicio : BOOL;  // Botón de inicio
    btnParo   : BOOL;  // Botón de paro
END_VAR

VAR_OUTPUT
    vLlenado  : BOOL;  // Válvula de llenado
    motorMezcla : BOOL;  // Motor de mezcla
    vDescarga : BOOL;  // Válvula de descarga
END_VAR

VAR
    estado : INT := 0;  // Estado actual del proceso
    timerMezcla : TON;  // Timer para el motor de mezcla
END_VAR

// Inicialización del timer
timerMezcla(IN := FALSE, PT := T#60S);

// Máquina de estados
CASE estado OF
    0:  // Reposo
        IF btnInicio THEN
            estado := 1;  // Iniciar el proceso de llenado
        END_IF;
    1:  // Llenado
        vLlenado := TRUE;
        IF nivelAlto THEN
            estado := 2;  // Pasar al siguiente estado después de alcanzar el nivel alto
        END_IF;
    2:  // Mezcla
        vLlenado := FALSE;
        motorMezcla := TRUE;
        timerMezcla(IN := TRUE);
        IF timerMezcla.Q THEN
            estado := 3;  // Pasar al siguiente estado después de 60 segundos
        END_IF;
    3:  // Descarga
        motorMezcla := FALSE;
        vDescarga := TRUE;
        IF nivelBajo THEN
            estado := 0;  // Regresar al reposo después de alcanzar el nivel bajo
        END_IF;
END_CASE;

// Manejo del botón de paro
IF btnParo THEN
    estado := 0;  // Regresar al reposo
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    timerMezcla(IN := FALSE);  // Detener el timer
END_IF;
```

Este código implementa una máquina de estados para controlar un proceso de llenado por etapas utilizando un FUNCTION_BLOCK en Structured Text (ST) conforme al estándar IEC 61131-3. El proceso pasa por las etapas de llenado, mezcla y descarga, y puede ser detenido en cualquier momento mediante el botón de paro, llevando todas las salidas a un estado seguro.