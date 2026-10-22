Aquí tienes el código en Structured Text (ST) para la lógica de selección de la fuente de mando de una bomba, utilizando un FUNCTION_BLOCK llamado `SelBomba`. Este bloque de función recibe las entradas `modoAuto`, `btnManual` y `nivelBajo`, y entrega el estado de la bomba a través de la salida `bomba`.

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
// Si modo automático está activo, la bomba se enciende si nivelBajo está activo
// Si modo automático no está activo, la bomba sigue el estado del botón manual
bomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);

END_FUNCTION_BLOCK
```

Este bloque de función `SelBomba` evalúa las condiciones de las entradas en cada ciclo de ejecución y determina el estado de la bomba en función del modo de operación seleccionado.