FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; // Indica si el quemador está encendido
END_VAR
VAR_OUTPUT
    ventilador : BOOL; // Controla el estado del ventilador
END_VAR
VAR
    timerTOF : TOF; // Temporizador de retardo a la desconexión (Off-Delay)
END_VAR

// Llamada al temporizador: 
// Mientras IN es TRUE, Q es TRUE. 
// Cuando IN pasa a FALSE, Q se mantiene TRUE durante el tiempo PT (30s) y luego pasa a FALSE.
timerTOF(IN := quemadorOn, PT := T#30S);

// Asignación de la salida del temporizador al ventilador
ventilador := timerTOF.Q;

END_FUNCTION_BLOCK