FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL; // Botón de arranque
    btnParo   : BOOL; // Botón de parada (prioridad a la parada)
END_VAR

VAR_OUTPUT
    kM : BOOL; // Contactor principal
    kY : BOOL; // Contactor de estrella
    kD : BOOL; // Contactor de triángulo
END_VAR

VAR
    tonEstrella   : TON; // Temporizador para la fase de estrella (8s)
    tonTransicion : TON; // Temporizador para el tiempo muerto (100ms)
END_VAR

// 1. Lógica del contactor principal (kM)
// Enclavamiento con btnMarcha, se rompe al pulsar btnParo
kM := (btnMarcha OR kM) AND NOT btnParo;

// 2. Temporizadores
// El temporizador de estrella inicia al arrancar el motor (kM = TRUE)
tonEstrella(IN := kM, PT := T#8S);

// El temporizador de transición inicia cuando termina la fase de estrella
tonTransicion(IN := tonEstrella.Q, PT := T#100MS);

// 3. Lógica de los contactores de fase (con enclavamiento mutuo de seguridad)
// kY se activa con kM, se apaga al terminar tonEstrella, y nunca si kD está activo
kY := kM AND NOT tonEstrella.Q AND NOT kD;

// kD se activa al terminar el tiempo muerto, y nunca si kY está activo
kD := kM AND tonTransicion.Q AND NOT kY;

END_FUNCTION_BLOCK