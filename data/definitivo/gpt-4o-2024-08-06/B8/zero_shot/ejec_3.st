```pascal
FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; // Señal de la puerta, TRUE si está abierta
    reset : BOOL;         // Señal de reset, TRUE para reiniciar el contador
END_VAR

VAR_OUTPUT
    aviso : BOOL;         // Señal de aviso, TRUE si se han acumulado 5 o más aperturas
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
    // Detecta el flanco ascendente de la señal puertaAbierta
    IF NOT puertaAbiertaAnt AND puertaAbierta THEN
        nAperturas := nAperturas + 1; // Incrementa el contador de aperturas
    END_IF

    // Activa la señal de aviso si se han acumulado 5 o más aperturas
    IF nAperturas >= 5 THEN
        aviso := TRUE;
    ELSE
        aviso := FALSE;
    END_IF
END_IF

// Actualiza el estado anterior de la señal puertaAbierta
puertaAbiertaAnt := puertaAbierta;

END_FUNCTION_BLOCK
```

Este código implementa un bloque de función `FB_Puerta` que cuenta las aperturas de una puerta y activa una señal de aviso cuando se alcanzan 5 aperturas. La señal de reset reinicia el contador y desactiva el aviso.