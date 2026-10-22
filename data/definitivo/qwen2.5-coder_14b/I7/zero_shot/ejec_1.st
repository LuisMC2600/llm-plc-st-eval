```pascal
FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL;  // Entrada que indica la demanda de arranque de las bombas
    falla1  : BOOL;  // Indica una falla en la bomba1
    falla2  : BOOL;  // Indica una falla en la bomba2
END_VAR

VAR_OUTPUT
    bomba1  : BOOL;  // Salida que controla el arranque de la bomba1
    bomba2  : BOOL;  // Salida que controla el arranque de la bomba2
    almFalla: BOOL;  // Alarma que indica una falla en la bomba principal con demanda presente
END_VAR

VAR
    estado  : INT;   // Variable de estado para controlar el ciclo de alternancia
    demandaAnterior : BOOL;  // Almacena el estado anterior de la demanda
END_VAR

// Inicialización de variables
IF NOT demandaAnterior AND demanda THEN
    estado := 1;  // Comienza con bomba1 como principal
END_IF

// Control de demanda
IF demanda THEN
    CASE estado OF
        1:
            bomba1 := TRUE;
            bomba2 := FALSE;
            IF falla1 THEN
                bomba1 := FALSE;
                bomba2 := TRUE;
                almFalla := TRUE;
            ELSE
                almFalla := FALSE;
            END_IF;
        2:
            bomba2 := TRUE;
            bomba1 := FALSE;
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
END_IF;

// Alternancia de estado en nueva demanda
IF NOT demandaAnterior AND demanda THEN
    IF estado = 1 THEN
        estado := 2;
    ELSE
        estado := 1;
    END_IF;
END_IF;

// Actualización del estado de demanda
demandaAnterior := demanda;
END_FUNCTION_BLOCK
```