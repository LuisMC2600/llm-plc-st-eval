```iecst
FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Sensor de nivel alto del tanque
END_VAR
VAR_OUTPUT
    valvula : BOOL; // Comando para abrir (TRUE) o cerrar (FALSE) la válvula
END_VAR
VAR
    temporizador : TON; // Temporizador de retardo a la conexión (Timer On Delay)
END_VAR

// El temporizador se activa con el sensor de nivel alto.
// Si nivelAlto es TRUE por 5 segundos continuos, la salida Q del temporizador será TRUE.
// Si nivelAlto pasa a FALSE, el temporizador se reinicia y Q pasa a FALSE inmediatamente.
temporizador(IN := nivelAlto, PT := T#5S);

// La válvula se abre solo cuando el temporizador ha cumplido el tiempo establecido.
valvula := temporizador.Q;

END_FUNCTION_BLOCK
```