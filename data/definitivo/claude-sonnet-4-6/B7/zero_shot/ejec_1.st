```pascal
// Selección de fuente de mando de bomba
// Sin memoria entre ciclos → FUNCTION (salida puramente combinacional)

FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto  : BOOL; // TRUE = modo automático, FALSE = modo manual
    btnManual : BOOL; // Botón de mando en modo manual
    nivelBajo : BOOL; // Señal de nivel bajo (activa = nivel bajo detectado)
END_VAR

// En modo automático la bomba sigue a nivelBajo;
// en modo manual la bomba sigue a btnManual.
SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);

END_FUNCTION
```