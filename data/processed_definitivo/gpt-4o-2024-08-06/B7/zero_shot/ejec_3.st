FUNCTION_BLOCK SelBomba
VAR_INPUT
    modoAuto : BOOL;    // Indica si el modo automático está activo
    btnManual : BOOL;   // Estado del botón manual
    nivelBajo : BOOL;   // Indica si el nivel bajo está activo
END_VAR
VAR_OUTPUT
    bomba : BOOL;       // Estado de la bomba
END_VAR

// Lógica de control de la bomba
bomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);

END_FUNCTION_BLOCK