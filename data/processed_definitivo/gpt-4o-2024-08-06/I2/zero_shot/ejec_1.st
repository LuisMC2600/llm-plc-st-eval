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
    timerMezcla : TON; // Temporizador para la mezcla
END_VAR

// Inicialización del temporizador de mezcla
timerMezcla(IN := FALSE, PT := T#60S);

// Lógica de control del proceso
IF btnParo THEN
    // Si se presiona el botón de paro, se detiene el proceso y se desactivan todas las salidas
    estado := 0;
    vLlenado := FALSE;
    motorMezcla := FALSE;
    vDescarga := FALSE;
ELSE
    CASE estado OF
        0: // Estado de reposo
            IF btnInicio THEN
                estado := 1; // Iniciar llenado
            END_IF;
        
        1: // Estado de llenado
            vLlenado := TRUE;
            IF nivelAlto THEN
                vLlenado := FALSE;
                estado := 2; // Pasar a mezcla
                timerMezcla(IN := TRUE); // Iniciar temporizador de mezcla
            END_IF;
        
        2: // Estado de mezcla
            motorMezcla := TRUE;
            IF timerMezcla.Q THEN
                motorMezcla := FALSE;
                estado := 3; // Pasar a descarga
            END_IF;
        
        3: // Estado de descarga
            vDescarga := TRUE;
            IF nivelBajo THEN
                vDescarga := FALSE;
                estado := 0; // Volver a reposo
            END_IF;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK