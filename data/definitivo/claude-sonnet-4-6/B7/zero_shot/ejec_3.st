```pascal
// Selección de fuente de mando para una bomba.
// Sin memoria entre ciclos: la salida depende solo de las entradas actuales.
FUNCTION SelBomba : BOOL
    VAR_INPUT
        modoAuto  : BOOL; // TRUE = modo automático, FALSE = modo manual
        btnManual : BOOL; // Botón de mando en modo manual
        nivelBajo : BOOL; // Señal de nivel bajo (activa la bomba en modo auto)
    END_VAR

    // En modo automático la bomba sigue a nivelBajo;
    // en modo manual la bomba sigue al botón.
    IF modoAuto THEN
        SelBomba := nivelBajo;
    ELSE
        SelBomba := btnManual;
    END_IF;

END_FUNCTION
```