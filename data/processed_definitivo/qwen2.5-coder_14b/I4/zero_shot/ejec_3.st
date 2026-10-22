FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL;   // Botón de paro
END_VAR

VAR_OUTPUT
    kM : BOOL; // Contactor principal
    kY : BOOL; // Contactor de estrella
    kD : BOOL; // Contactor de triángulo
END_VAR

VAR
    timerEstrella : TON; // Temporizador para el contacto de estrella
    timerMuerto : TON;   // Temporizador para el tiempo muerto
    estado : INT;       // Estado actual del arranque estrella-triángulo
END_VAR

// Estados del arranque estrella-triángulo
CONST
    ESTADO_INICIAL := 0;
    ESTADO_MARCHA := 1;
    ESTADO_TIEMPO_MUERTO := 2;
    ESTADO_TRIANGULO := 3;
END_CONST

// Inicialización
IF NOT btnParo THEN
    CASE estado OF
        ESTADO_INICIAL:
            kM := FALSE;
            kY := FALSE;
            kD := FALSE;
            IF btnMarcha THEN
                estado := ESTADO_MARCHA;
                kM := TRUE;
                kY := TRUE;
                timerEstrella(IN := TRUE, PT := T#8S);
            END_IF;
        
        ESTADO_MARCHA:
            IF timerEstrella.Q THEN
                estado := ESTADO_TIEMPO_MUERTO;
                kY := FALSE;
                timerMuerto(IN := TRUE, PT := T#100MS);
            END_IF;
        
        ESTADO_TIEMPO_MUERTO:
            IF timerMuerto.Q THEN
                estado := ESTADO_TRIANGULO;
                kD := TRUE;
            END_IF;
        
        ESTADO_TRIANGULO:
            // Mantener kD activo mientras no se presione btnParo
            kD := TRUE;
    END_CASE;
ELSE
    // Paro forzado
    estado := ESTADO_INICIAL;
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    timerEstrella(IN := FALSE);
    timerMuerto(IN := FALSE);
END_IF;