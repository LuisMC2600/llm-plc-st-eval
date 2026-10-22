```pascal
PROGRAM SelBomba
VAR
    modoAuto : BOOL;  // Entrada que indica si el sistema está en modo automático
    btnManual : BOOL; // Entrada que indica el estado del botón manual
    nivelBajo : BOOL; // Entrada que indica si el nivel está por debajo del umbral
    bomba : BOOL;     // Salida que indica el estado de la bomba
END_VAR

// Lógica de selección de la fuente de mando de la bomba
IF modoAuto THEN
    // En modo automático, la bomba está encendida si nivelBajo está activo
    bomba := nivelBajo;
ELSE
    // En modo manual, la bomba obedece directamente al botón btnManual
    bomba := btnManual;
END_IF;
```

Este programa en Structured Text (ST) implementa la lógica de selección de la fuente de mando de una bomba según las especificaciones proporcionadas. La variable `bomba` indica el estado de la bomba, que depende de las entradas `modoAuto`, `btnManual` y `nivelBajo`.