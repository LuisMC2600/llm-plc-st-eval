FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; // Entrada que indica si la puerta está abierta
    reset : BOOL; // Entrada para resetear el contador de aperturas
END_VAR

VAR_OUTPUT
    aviso : BOOL; // Salida que indica si se han acumulado 5 o más aperturas
    nAperturas : INT; // Salida que muestra el número de aperturas
END_VAR

VAR
    puertaAbiertaAnterior : BOOL; // Variable para almacenar el estado anterior de puertaAbierta
END_VAR

// Inicialización de variables
IF NOT puertaAbiertaAnterior THEN
    puertaAbiertaAnterior := puertaAbierta;
END_IF

// Lógica de reset
IF reset THEN
    nAperturas := 0;
    aviso := FALSE;
END_IF

// Contador de aperturas
IF puertaAbierta AND NOT puertaAbiertaAnterior THEN
    nAperturas := nAperturas + 1;
END_IF

// Actualización del estado anterior de puertaAbierta
puertaAbiertaAnterior := puertaAbierta;

// Lógica de aviso
IF nAperturas >= 5 THEN
    aviso := TRUE;
ELSE
    aviso := FALSE;
END_IF
END_FUNCTION_BLOCK