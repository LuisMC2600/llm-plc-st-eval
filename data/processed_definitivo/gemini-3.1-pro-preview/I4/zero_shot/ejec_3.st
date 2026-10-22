FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de arranque
    btnParo   : BOOL; // Botón de parada (TRUE = detener)
END_VAR

VAR_OUTPUT
    kM : BOOL; // Contactor principal
    kY : BOOL; // Contactor de estrella
    kD : BOOL; // Contactor de triángulo
END_VAR

VAR
    bRun        : BOOL; // Memoria del estado de marcha
    tonStar     : TON;  // Temporizador para la fase de estrella
    tonDeadTime : TON;  // Temporizador para el tiempo muerto
END_VAR

// 1. Lógica de retención (Marcha / Paro)
// El paro tiene prioridad sobre la marcha
IF btnParo THEN
    bRun := FALSE;
ELSIF btnMarcha THEN
    bRun := TRUE;
END_IF;

// 2. Temporizador de la fase de estrella (8 segundos)
tonStar(IN := bRun, PT := T#8S);

// 3. Control del contactor de Estrella (kY)
// Activo si hay marcha, no ha terminado el tiempo de estrella y kD está apagado (enclavamiento)
kY := bRun AND NOT tonStar.Q AND NOT kD;

// 4. Temporizador de tiempo muerto (100 milisegundos)
// Comienza a contar solo cuando termina la fase de estrella y kY se ha desactivado
tonDeadTime(IN := tonStar.Q AND NOT kY, PT := T#100MS);

// 5. Control del contactor de Triángulo (kD)
// Activo si hay marcha, terminó el tiempo muerto y kY está apagado (enclavamiento)
kD := bRun AND tonDeadTime.Q AND NOT kY;

// 6. Control del contactor Principal (kM)
// Activo siempre que el sistema esté en marcha
kM := bRun;

END_FUNCTION_BLOCK