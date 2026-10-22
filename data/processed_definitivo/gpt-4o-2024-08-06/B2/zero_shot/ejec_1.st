FUNCTION_BLOCK FB_Valvula
VAR
    nivelAlto : BOOL; // Entrada: estado del sensor de nivel alto
    valvula : BOOL;   // Salida: estado de la válvula de drenaje
    timer : TON;      // Temporizador para el retardo de 5 segundos
END_VAR

// Implementación del bloque de función
timer(IN := nivelAlto, PT := T#5S); // Configuración del temporizador

// Lógica de control de la válvula
IF timer.Q THEN
    valvula := TRUE;  // Abre la válvula si el temporizador ha alcanzado el tiempo establecido
ELSE
    valvula := FALSE; // Cierra la válvula si el nivel alto no se mantiene
END_IF
END_FUNCTION_BLOCK