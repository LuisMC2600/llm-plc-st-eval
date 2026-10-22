FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA     : BOOL; // Sensor de nivel alcanzado para componente A
    nivelB     : BOOL; // Sensor de nivel alcanzado para componente B
    nivelVacio : BOOL; // Sensor de reactor vacío
    btnInicio  : BOOL; // Botón para iniciar la receta
    btnAbort   : BOOL; // Botón para abortar el proceso
    temp       : REAL; // Temperatura actual del reactor
END_VAR

VAR_OUTPUT
    vA         : BOOL; // Válvula de dosificación componente A
    vB         : BOOL; // Válvula de dosificación componente B
    calentador : BOOL; // Actuador del calentador
    mezclador  : BOOL; // Actuador del mezclador
    vDescarga  : BOOL; // Válvula de descarga
    fase       : INT;  // Fase actual del proceso (0 a 5)
END_VAR

VAR
    TON_Mezcla : TON;  // Temporizador para la fase de mezclado
END_VAR

// ---------------------------------------------------------
// Lógica de Aborto
// ---------------------------------------------------------
IF btnAbort AND fase > 0 THEN
    IF fase <> 5 THEN
        IF NOT nivelVacio THEN
            fase := 5; // Si hay producto, pasar a descarga
        ELSE
            fase := 0; // Si está vacío, pasar a reposo
        END_IF;
    END_IF;
    // Si la fase ya es 5, el aborto no hace nada y continúa la descarga
END_IF;

// ---------------------------------------------------------
// Máquina de Estados (Receta)
// ---------------------------------------------------------
CASE fase OF
    0: // Fase 0: Reposo
        IF btnInicio THEN
            fase := 1;
        END_IF;
        
    1: // Fase 1: Dosificar componente A
        IF nivelA THEN
            fase := 2;
        END_IF;
        
    2: // Fase 2: Dosificar componente B
        IF nivelB THEN
            fase := 3;
        END_IF;
        
    3: // Fase 3: Calentar
        IF temp >= 60.0 THEN
            fase := 4;
        END_IF;
        
    4: // Fase 4: Mezclar
        IF TON_Mezcla.Q THEN
            fase := 5;
        END_IF;
        
    5: // Fase 5: Descargar
        IF nivelVacio THEN
            fase := 0;
        END_IF;
END_CASE;

// ---------------------------------------------------------
// Actualización de Temporizadores
// ---------------------------------------------------------
// El temporizador solo avanza cuando la fase activa es la 4
TON_Mezcla(IN := (fase = 4), PT := T#120S);

// ---------------------------------------------------------
// Asignación de Salidas
// ---------------------------------------------------------
// Las salidas se activan exclusivamente en su fase correspondiente.
// Un aborto cierra inmediatamente vA, vB, calentador y mezclador al cambiar la fase.
vA         := (fase = 1);
vB         := (fase = 2);
calentador := (fase = 3);
mezclador  := (fase = 4);
vDescarga  := (fase = 5);

END_FUNCTION_BLOCK