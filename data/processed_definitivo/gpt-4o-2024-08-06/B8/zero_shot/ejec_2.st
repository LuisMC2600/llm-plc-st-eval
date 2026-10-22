FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; // Señal de la puerta, TRUE si está abierta
    reset : BOOL;         // Señal para resetear el contador de aperturas
END_VAR

VAR_OUTPUT
    aviso : BOOL;         // Señal de aviso, TRUE si se alcanzan 5 o más aperturas
    nAperturas : INT;     // Contador de aperturas de la puerta
END_VAR

VAR
    puertaAbiertaAnt : BOOL; // Estado anterior de la señal puertaAbierta
END_VAR

// Inicialización de variables
IF reset THEN
    nAperturas := 0;      // Reinicia el contador de aperturas
    aviso := FALSE;       // Desactiva la señal de aviso
ELSE
    // Detecta la transición de FALSE a TRUE de puertaAbierta
    IF NOT puertaAbiertaAnt AND puertaAbierta THEN
        nAperturas := nAperturas + 1; // Incrementa el contador de aperturas
    END_IF
    
    // Activa la señal de aviso si se alcanzan 5 o más aperturas
    IF nAperturas >= 5 THEN
        aviso := TRUE;
    ELSE
        aviso := FALSE;
    END_IF
END_IF

// Actualiza el estado anterior de la puerta
puertaAbiertaAnt := puertaAbierta;

END_FUNCTION_BLOCK