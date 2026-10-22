```pascal
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de marcha
    btnParo   : BOOL; // Botón de paro
END_VAR

VAR_OUTPUT
    kM : BOOL := FALSE; // Contactor principal
    kY : BOOL := FALSE; // Contactor estrella
    kD : BOOL := FALSE; // Contactor triángulo
END_VAR

VAR
    estado : INT := 0; // Estado del proceso
    timerEstrella : TON; // Temporizador para el modo estrella
    timerMuerto : TON; // Temporizador para el tiempo muerto
END_VAR

// Inicialización de temporizadores
timerEstrella(IN := FALSE, PT := T#8S);
timerMuerto(IN := FALSE, PT := T#100MS);

IF btnParo THEN
    // Reset de todos los contactores y estado
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0: // Estado inicial
            kM := TRUE; // Activar contactor principal
            kY := TRUE; // Activar contactor estrella
            timerEstrella(IN := TRUE); // Iniciar temporizador estrella
            estado := 1; // Cambiar al siguiente estado

        1: // Esperando a que termine el temporizador estrella
            IF timerEstrella.Q THEN
                kY := FALSE; // Desactivar contactor estrella
                timerEstrella(IN := FALSE); // Reset temporizador estrella
                timerMuerto(IN := TRUE); // Iniciar temporizador muerto
                estado := 2; // Cambiar al siguiente estado
            END_IF

        2: // Esperando a que termine el tiempo muerto
            IF timerMuerto.Q THEN
                timerMuerto(IN := FALSE); // Reset temporizador muerto
                kD := TRUE; // Activar contactor triángulo
                estado := 3; // Cambiar al siguiente estado
            END_IF

        3: // Estado final, triángulo activado
            // Mantener kM y kD activados
            // No se requiere acción adicional
    END_CASE
ELSE
    // Si no se presiona btnMarcha, asegurarse de que los contactores están apagados
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
END_IF
END_FUNCTION_BLOCK
```

Este código implementa un arranque estrella-triángulo utilizando un bloque de función en Structured Text (ST) conforme al estándar IEC 61131-3. El bloque maneja el proceso de arranque y parada del motor, asegurando que los contactores estrella y triángulo no estén activos simultáneamente.