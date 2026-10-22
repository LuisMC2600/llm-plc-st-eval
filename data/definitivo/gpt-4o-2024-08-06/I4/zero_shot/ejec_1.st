```pascal
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo : BOOL;   // Botón de paro
END_VAR

VAR_OUTPUT
    kM : BOOL := FALSE; // Contactor principal
    kY : BOOL := FALSE; // Contactor estrella
    kD : BOOL := FALSE; // Contactor triángulo
END_VAR

VAR
    timerEstrella : TON; // Temporizador para el modo estrella
    timerMuerto : TON;   // Temporizador para el tiempo muerto
    estado : INT := 0;   // Estado del proceso
END_VAR

// Implementación del arranque estrella-triángulo
IF btnParo THEN
    // Si se presiona el botón de paro, desactivar todos los contactores y resetear el estado
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSE
    CASE estado OF
        0: // Estado inicial
            IF btnMarcha THEN
                // Al presionar el botón de marcha, activar el contactor principal y el de estrella
                kM := TRUE;
                kY := TRUE;
                timerEstrella(IN := TRUE, PT := T#8S);
                estado := 1;
            END_IF

        1: // Estado de temporización en estrella
            IF timerEstrella.Q THEN
                // Después de 8 segundos, desactivar el contactor de estrella y activar el temporizador muerto
                kY := FALSE;
                timerEstrella(IN := FALSE);
                timerMuerto(IN := TRUE, PT := T#100MS);
                estado := 2;
            END_IF

        2: // Estado de tiempo muerto
            IF timerMuerto.Q THEN
                // Después de 100 ms, activar el contactor de triángulo
                timerMuerto(IN := FALSE);
                kD := TRUE;
                estado := 3;
            END_IF

        3: // Estado de funcionamiento en triángulo
            // Mantener el estado hasta que se presione el botón de paro
            // No se requiere acción adicional aquí
    END_CASE
END_IF
END_FUNCTION_BLOCK
```

Este código implementa un arranque estrella-triángulo utilizando un bloque de función en Structured Text (ST) conforme al estándar IEC 61131-3. El proceso se controla mediante un estado finito que avanza a través de las etapas de arranque, temporización en estrella, tiempo muerto y funcionamiento en triángulo.