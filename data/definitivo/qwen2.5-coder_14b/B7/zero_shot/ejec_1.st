```pascal
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
```

Este programa en Structured Text (ST) cumple con los requisitos especificados. Utiliza un PROGRAM para encapsular la lógica de selección de la fuente de mando de la bomba. Las variables de entrada y salida se declaran al principio, y la lógica se implementa utilizando una estructura IF-ELSE para determinar el estado de la bomba según el modo seleccionado.