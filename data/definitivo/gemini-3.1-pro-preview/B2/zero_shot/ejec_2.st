```iecst
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Indica si el sensor de nivel alto está activo
END_VAR

VAR_OUTPUT
    valvula : BOOL; // Comando para abrir (TRUE) o cerrar (FALSE) la válvula de drenaje
END_VAR

VAR
    temporizador : TON; // Temporizador con retardo a la conexión (On-Delay)
END_VAR

// El temporizador evalúa si el nivel alto se mantiene activo por 5 segundos continuos.
// Si nivelAlto pasa a FALSE, el temporizador se reinicia y su salida Q pasa a FALSE de inmediato.
temporizador(IN := nivelAlto, PT := T#5S);

// La válvula se abre solo cuando el temporizador ha cumplido el tiempo establecido.
valvula := temporizador.Q;

END_FUNCTION_BLOCK
```