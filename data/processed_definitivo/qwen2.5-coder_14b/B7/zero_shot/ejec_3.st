PROGRAM SelBomba
VAR
    modoAuto : BOOL;   // Entrada que indica si el sistema está en modo automático
    btnManual : BOOL;  // Entrada que indica el estado del botón manual
    nivelBajo : BOOL;  // Entrada que indica si el nivel está por debajo del umbral
    bomba : BOOL;      // Salida que indica el estado de la bomba
END_VAR

// Lógica de selección de la fuente de mando de la bomba
IF modoAuto THEN
    // En modo automático, la bomba está encendida si nivelBajo está activo
    bomba := nivelBajo;
ELSE
    // En modo manual, la bomba obedece al botón manual
    bomba := btnManual;
END_IF;