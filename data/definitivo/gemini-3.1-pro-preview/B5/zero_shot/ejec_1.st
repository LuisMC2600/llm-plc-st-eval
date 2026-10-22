```iecst
FUNCTION_BLOCK FB_Ventilador
VAR_INPUT
    quemadorOn : BOOL; // Indica si el quemador está encendido
END_VAR
VAR_OUTPUT
    ventilador : BOOL; // Controla el estado del ventilador
END_VAR
VAR
    temporizadorTOF : TOF; // Temporizador de retardo a la desconexión (Off-Delay)
END_VAR

// El temporizador TOF mantiene su salida Q en TRUE mientras IN sea TRUE, 
// y la mantiene 30 segundos adicionales después de que IN pase a FALSE.
temporizadorTOF(IN := quemadorOn, PT := T#30S);

// Asignación directa de la salida del temporizador al ventilador
ventilador := temporizadorTOF.Q;

END_FUNCTION_BLOCK
```