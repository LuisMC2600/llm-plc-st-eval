```pascal
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
```

Este código define un programa (`PROGRAM`) llamado `SelBomba` que implementa la lógica de control de una bomba basada en el modo de operación seleccionado (automático o manual). Las entradas son `modoAuto`, `btnManual` y `nivelBajo`, y la salida es `bomba`, que indica el estado actual de la bomba.