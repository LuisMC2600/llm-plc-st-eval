FUNCTION_BLOCK FB_Valvula
VAR_INPUT
    nivelAlto : BOOL; // Señal del sensor de nivel alto
END_VAR

VAR_OUTPUT
    valvula : BOOL;   // Comando para abrir (TRUE) o cerrar (FALSE) la válvula
END_VAR

VAR
    tonRetardo : TON; // Temporizador de retardo a la conexión (Timer On Delay)
END_VAR

// Configuración y ejecución del temporizador
// IN: Inicia el conteo si nivelAlto es TRUE. Se resetea inmediatamente si es FALSE.
// PT: Tiempo de retardo establecido en 5 segundos.
tonRetardo(IN := nivelAlto, PT := T#5S);

// La salida del temporizador (Q) se activa tras 5 segundos continuos de nivel alto.
// Si nivelAlto pasa a FALSE, Q se desactiva de inmediato, cerrando la válvula.
valvula := tonRetardo.Q;

END_FUNCTION_BLOCK