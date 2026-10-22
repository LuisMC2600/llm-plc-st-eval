FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL;  // Entrada que indica la demanda de arranque de las bombas
    falla1 : BOOL;   // Indica si la bomba1 tiene una falla
    falla2 : BOOL;   // Indica si la bomba2 tiene una falla
END_VAR

VAR_OUTPUT
    bomba1 : BOOL;  // Salida que controla el arranque de la bomba1
    bomba2 : BOOL;  // Salida que controla el arranque de la bomba2
    almFalla : BOOL; // Alarma que indica una falla en la bomba principal con demanda presente
END_VAR

VAR
    estado : INT := 0;  // Estado actual del sistema (0: detenido, 1: bomba1 principal, 2: bomba2 principal)
    demandaAnterior : BOOL := FALSE;  // Almacena el estado anterior de la demanda
END_VAR

// Programa principal
IF demanda THEN
    CASE estado OF
        0:  // Estado detenido
            estado := 1;  // Cambia a bomba1 como principal
            bomba1 := TRUE;
            bomba2 := FALSE;
        1:  // Bomba1 principal
            IF falla1 THEN
                bomba1 := FALSE;
                bomba2 := TRUE;
                almFalla := TRUE;
            ELSE
                almFalla := FALSE;
            END_IF;
        2:  // Bomba2 principal
            IF falla2 THEN
                bomba2 := FALSE;
                bomba1 := TRUE;
                almFalla := TRUE;
            ELSE
                almFalla := FALSE;
            END_IF;
    END_CASE;
ELSE
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
    estado := 0;  // Cambia a estado detenido
END_IF;

// Alterna el rol de principal en cada nueva demanda
IF demanda AND NOT demandaAnterior THEN
    CASE estado OF
        1: estado := 2;
        2: estado := 1;
    END_CASE;
END_IF;

// Actualiza el estado anterior de la demanda
demandaAnterior := demanda;
END_FUNCTION_BLOCK