FUNCTION_BLOCK FB_Valvula
VAR
    nivelAlto : BOOL; // Entrada: indica si el nivel alto está activo
    valvula : BOOL;   // Salida: controla el estado de la válvula
    timer : TON;      // Temporizador para el retardo de 5 segundos
END_VAR

// Implementación del bloque de función
timer(IN := nivelAlto, PT := T#5S); // Configuración del temporizador

// Lógica de control de la válvula
IF timer.Q THEN
    valvula := TRUE;  // Abre la válvula si el temporizador ha expirado
ELSE
    valvula := FALSE; // Cierra la válvula si el nivel alto no está activo
END_IF;