```pascal
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
IF reset THEN
    nAperturas := 0;
    aviso := FALSE;
    puertaAbiertaAnterior := FALSE;
END_IF

// Detectar transición de FALSE a TRUE en puertaAbierta
IF NOT puertaAbiertaAnterior AND puertaAbierta THEN
    nAperturas := nAperturas + 1;
END_IF

// Actualizar el estado anterior de puertaAbierta
puertaAbiertaAnterior := puertaAbierta;

// Activar la salida de aviso si se han acumulado 5 o más aperturas
IF nAperturas >= 5 THEN
    aviso := TRUE;
ELSE
    aviso := FALSE;
END_IF
END_FUNCTION_BLOCK
```