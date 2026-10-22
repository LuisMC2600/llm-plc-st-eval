FUNCTION_BLOCK FB_Ventilador
VAR
    // Variable de entrada
    quemadorOn : BOOL; // Estado del quemador: TRUE si está encendido, FALSE si está apagado

    // Variable de salida
    ventilador : BOOL; // Estado del ventilador: TRUE si está encendido, FALSE si está apagado

    // Variables internas
    timer : TON; // Temporizador para controlar el tiempo adicional de funcionamiento del ventilador
END_VAR

// Inicialización del temporizador
timer(IN := NOT quemadorOn, PT := T#30S);

// Lógica de control del ventilador
IF quemadorOn THEN
    ventilador := TRUE; // El ventilador está encendido mientras el quemador está encendido
ELSE
    timer(IN := TRUE); // Iniciar el temporizador cuando el quemador se apaga
    ventilador := timer.Q; // El ventilador sigue encendido mientras el temporizador está activo
END_IF;