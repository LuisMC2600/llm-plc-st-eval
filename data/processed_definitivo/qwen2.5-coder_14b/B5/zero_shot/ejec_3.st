FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; // Estado del quemador (encendido/apagado)
END_VAR

VAR_OUTPUT
    ventilador : BOOL; // Estado del ventilador (encendido/apagado)
END_VAR

VAR
    timer : TON; // Timer de retardo
    timerDone : BOOL; // Bandera para indicar que el timer ha terminado
END_VAR

// Inicialización del timer
IF NOT timer.Q THEN
    timer(IN := FALSE, PT := T#30S);
END_IF;

// Lógica del ventilador
IF quemadorOn THEN
    ventilador := TRUE; // El ventilador se enciende cuando el quemador está encendido
    timer(IN := FALSE); // Reinicia el timer
ELSE
    IF NOT timer.Q THEN
        timer(IN := TRUE); // Inicia el timer cuando el quemador se apaga
    END_IF;
    ventilador := timer.Q; // El ventilador se apaga cuando el timer termina
END_IF;