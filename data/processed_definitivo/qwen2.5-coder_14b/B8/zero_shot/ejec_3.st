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
    puertaAbiertaAnterior : BOOL := FALSE; // Variable para almacenar el estado anterior de la puerta
END_VAR

// Comprueba si se ha reseteado el sistema
IF reset THEN
    nAperturas := 0; // Reinicia el contador de aperturas
    aviso := FALSE; // Desactiva el aviso
ELSE
    // Comprueba si la puerta ha pasado de cerrada a abierta
    IF NOT puertaAbiertaAnterior AND puertaAbierta THEN
        nAperturas := nAperturas + 1; // Incrementa el contador de aperturas
    END_IF

    // Actualiza el estado anterior de la puerta
    puertaAbiertaAnterior := puertaAbierta;

    // Comprueba si se han acumulado 5 o más aperturas
    IF nAperturas >= 5 THEN
        aviso := TRUE; // Activa el aviso
    ELSE
        aviso := FALSE; // Desactiva el aviso
    END_IF
END_IF
END_FUNCTION_BLOCK