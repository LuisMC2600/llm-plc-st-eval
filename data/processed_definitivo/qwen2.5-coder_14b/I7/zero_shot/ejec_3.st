FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL;  // Entrada que indica si hay demanda de bomba
    falla1 : BOOL;   // Indica si la bomba1 tiene falla
    falla2 : BOOL;   // Indica si la bomba2 tiene falla
END_VAR

VAR_OUTPUT
    bomba1 : BOOL;  // Salida para controlar la bomba1
    bomba2 : BOOL;  // Salida para controlar la bomba2
    almFalla : BOOL; // Alarma de falla de la bomba principal
END_VAR

VAR
    estado : INT := 0;  // Estado actual del bloque (0: detenido, 1: bomba1 principal, 2: bomba2 principal)
    demandaAnterior : BOOL := FALSE;  // Almacena el estado anterior de la demanda
END_VAR

// Programa principal
IF demanda THEN
    CASE estado OF
        0:  // Estado detenido
            estado := 1;  // Cambia a bomba1 principal
            bomba1 := TRUE;
            bomba2 := FALSE;
        1:  // Bomba1 principal
            IF falla1 THEN
                bomba1 := FALSE;
                bomba2 := TRUE;
                almFalla := TRUE;
            ELSE
                IF falla2 THEN
                    bomba2 := FALSE;
                END_IF;
            END_IF;
        2:  // Bomba2 principal
            IF falla2 THEN
                bomba2 := FALSE;
                bomba1 := TRUE;
                almFalla := TRUE;
            ELSE
                IF falla1 THEN
                    bomba1 := FALSE;
                END_IF;
            END_IF;
    END_CASE;
ELSE
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
    estado := 0;  // Cambia a estado detenido
END_IF;

// Alternar el rol de la bomba principal en cada nueva demanda
IF demanda AND NOT demandaAnterior THEN
    CASE estado OF
        1: estado := 2;  // Cambia a bomba2 principal
        2: estado := 1;  // Cambia a bomba1 principal
    END_CASE;
END_IF;

// Actualizar el estado anterior de la demanda
demandaAnterior := demanda;
END_FUNCTION_BLOCK