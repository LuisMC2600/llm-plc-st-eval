FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; // Señal de demanda para arrancar el sistema
    falla1  : BOOL; // Señal de falla activa de la bomba 1
    falla2  : BOOL; // Señal de falla activa de la bomba 2
END_VAR

VAR_OUTPUT
    bomba1   : BOOL; // Comando de operación para la bomba 1
    bomba2   : BOOL; // Comando de operación para la bomba 2
    almFalla : BOOL; // Alarma de falla de la bomba principal con demanda presente
END_VAR

VAR
    rTrigDemanda    : R_TRIG; // Detector de flanco de subida de la demanda
    bomba1Principal : BOOL := TRUE; // Indica si la bomba 1 tiene el rol principal
    primerArranque  : BOOL := TRUE; // Bandera para identificar la primera demanda
END_VAR

// Detección del flanco de subida de la señal de demanda
rTrigDemanda(CLK := demanda);

// Lógica de alternancia en cada nueva demanda
IF rTrigDemanda.Q THEN
    IF primerArranque THEN
        // En la primera demanda tras el arranque, la principal es la bomba 1
        primerArranque := FALSE;
    ELSE
        // En las demandas posteriores, se alterna el rol principal
        bomba1Principal := NOT bomba1Principal;
    END_IF;
END_IF;

// Lógica de control de operación y respaldo
IF demanda THEN
    IF bomba1Principal THEN
        // Bomba 1 es la principal, Bomba 2 es el respaldo
        bomba1   := NOT falla1;
        bomba2   := falla1 AND NOT falla2;
        almFalla := falla1;
    ELSE
        // Bomba 2 es la principal, Bomba 1 es el respaldo
        bomba2   := NOT falla2;
        bomba1   := falla2 AND NOT falla1;
        almFalla := falla2;
    END_IF;
ELSE
    // Al desactivarse la demanda, ambas bombas se detienen y se apaga la alarma
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;
END_IF;

END_FUNCTION_BLOCK