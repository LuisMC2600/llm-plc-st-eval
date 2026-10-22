Aquí tienes el código en Structured Text (ST) para un FUNCTION_BLOCK llamado `SelBomba`, que implementa la lógica de selección de la fuente de mando de una bomba conforme a tu descripción:

```pascal
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
```

### Explicación:
- **modoAuto**: Entrada booleana que indica si el modo automático está activo.
- **btnManual**: Entrada booleana que representa el estado del botón manual.
- **nivelBajo**: Entrada booleana que indica si el nivel bajo está activo.
- **bomba**: Salida booleana que representa el estado de la bomba.

La lógica implementada en el bloque `SelBomba` establece que la bomba se enciende si:
- El modo automático está activo y el nivel bajo está activo, o
- El modo manual está activo (modo automático no activo) y el botón manual está presionado.