PROGRAM SelBomba
VAR
    modoAuto : BOOL;    // Entrada: selecciona el modo automático
    btnManual : BOOL;   // Entrada: botón manual para encender la bomba
    nivelBajo : BOOL;   // Entrada: indica si el nivel es bajo
    bomba : BOOL;       // Salida: estado de la bomba
END_VAR

// Lógica de selección de la fuente de mando de la bomba
IF modoAuto THEN
    // Modo automático: la bomba se enciende si nivelBajo está activo
    bomba := nivelBajo;
ELSE
    // Modo manual: la bomba sigue el estado del botón manual
    bomba := btnManual;
END_IF;