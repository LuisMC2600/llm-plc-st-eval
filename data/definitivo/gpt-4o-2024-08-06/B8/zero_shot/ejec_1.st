```pascal
FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; // Señal de la puerta, TRUE si está abierta
    reset : BOOL;         // Señal de reset, TRUE para reiniciar el contador
END_VAR

VAR_OUTPUT
    aviso : BOOL;         // Señal de aviso, TRUE si se han alcanzado 5 aperturas
    nAperturas : INT;     // Contador de aperturas de la puerta
END_VAR

VAR
    puertaAbiertaAnt : BOOL; // Estado anterior de la señal puertaAbierta
END_VAR

// Inicialización
IF reset THEN
    nAperturas := 0;      // Reinicia el contador de aperturas
    aviso := FALSE;       // Desactiva el aviso
ELSE
    // Detecta la transición de FALSE a TRUE de puertaAbierta
    IF NOT puertaAbiertaAnt AND puertaAbierta THEN
        nAperturas := nAperturas + 1; // Incrementa el contador
    END_IF

    // Activa el aviso si se alcanzan 5 o más aperturas
    IF nAperturas >= 5 THEN
        aviso := TRUE;
    ELSE
        aviso := FALSE;
    END_IF
END_IF

// Actualiza el estado anterior de puertaAbierta
puertaAbiertaAnt := puertaAbierta;

END_FUNCTION_BLOCK
```

Este código define un bloque de función `FB_Puerta` que registra las aperturas de una puerta de seguridad. El contador de aperturas se incrementa solo en la transición de la señal `puertaAbierta` de `FALSE` a `TRUE`. Cuando se alcanzan 5 o más aperturas, se activa la señal de `aviso`. La señal de `reset` reinicia el contador y desactiva el aviso.