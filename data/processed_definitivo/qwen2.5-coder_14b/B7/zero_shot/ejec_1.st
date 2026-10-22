PROGRAM SelBomba
VAR
    modoAuto : BOOL;    // Entrada que indica el modo automático
    btnManual : BOOL;   // Entrada que indica el botón manual
    nivelBajo : BOOL;  // Entrada que indica el nivel bajo
    bomba : BOOL;       // Salida que indica el estado de la bomba
END_VAR

// Lógica de selección de la fuente de mando de la bomba
IF modoAuto THEN
    // Modo automático: la bomba está encendida si nivelBajo está activo
    bomba := nivelBajo;
ELSE
    // Modo manual: la bomba obedece al botón btnManual
    bomba := btnManual;
END_IF;