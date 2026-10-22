```pascal
FUNCTION_BLOCK FB_Llenado
VAR
    // Entradas
    nivelAlto : BOOL;
    nivelBajo : BOOL;
    btnInicio : BOOL;
    btnParo : BOOL;

    // Salidas
    vLlenado : BOOL := FALSE;
    motorMezcla : BOOL := FALSE;
    vDescarga : BOOL := FALSE;

    // Variables internas
    estado : INT := 0; // 0: Reposo, 1: Llenado, 2: Mezcla, 3: Descarga
    timerMezcla : TON; // Temporizador para el motor de mezcla
END_VAR

// Inicialización del temporizador
timerMezcla(IN := FALSE, PT := T#60S);

IF btnParo THEN
    // Si se presiona el botón de paro, se desactivan todas las salidas y se vuelve a reposo
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
    estado := 0;
ELSE
    CASE estado OF
        0: // Reposo
            IF btnInicio THEN
                estado := 1; // Cambiar al estado de llenado
            END_IF;

        1: // Llenado
            vLlenado := TRUE;
            IF nivelAlto THEN
                vLlenado := FALSE;
                estado := 2; // Cambiar al estado de mezcla
                timerMezcla(IN := TRUE); // Iniciar temporizador de mezcla
            END_IF;

        2: // Mezcla
            motorMezcla := TRUE;
            timerMezcla(IN := TRUE);
            IF timerMezcla.Q THEN
                motorMezcla := FALSE;
                estado := 3; // Cambiar al estado de descarga
            END_IF;

        3: // Descarga
            vDescarga := TRUE;
            IF nivelBajo THEN
                vDescarga := FALSE;
                estado := 0; // Volver al estado de reposo
            END_IF;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Llenado` que gestiona un proceso de llenado por etapas. El proceso se controla mediante un estado interno que cambia en función de las entradas y condiciones del sistema. El temporizador `TON` se utiliza para controlar el tiempo de mezcla.