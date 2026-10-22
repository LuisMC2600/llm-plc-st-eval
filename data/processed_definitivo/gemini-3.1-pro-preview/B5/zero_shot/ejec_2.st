FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; // Indica si el quemador está encendido
END_VAR

VAR_OUTPUT
    ventilador : BOOL; // Comando de encendido para el ventilador
END_VAR

VAR
    temporizadorTOF : TOF; // Temporizador de retardo a la desconexión (Off-Delay)
END_VAR

// Configuración y ejecución del temporizador
// Si quemadorOn es TRUE, la salida Q es TRUE inmediatamente.
// Cuando quemadorOn pasa a FALSE, Q se mantiene TRUE durante el tiempo PT (30s) y luego pasa a FALSE.
temporizadorTOF(IN := quemadorOn, PT := T#30S);

// Asignación del estado del temporizador a la salida del ventilador
ventilador := temporizadorTOF.Q;

END_FUNCTION_BLOCK