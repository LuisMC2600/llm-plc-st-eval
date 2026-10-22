```pascal
// Selección de fuente de mando de una bomba.
// Sin memoria entre ciclos: la salida depende solo de las entradas actuales.
FUNCTION SelBomba : BOOL
    VAR_INPUT
        modoAuto  : BOOL; // TRUE = modo automático, FALSE = modo manual
        btnManual : BOOL; // Botón de mando en modo manual
        nivelBajo : BOOL; // Señal de nivel bajo (activa = nivel bajo detectado)
    END_VAR

    // En modo automático la bomba arranca por nivel bajo;
    // en modo manual obedece directamente al botón.
    IF modoAuto THEN
        SelBomba := nivelBajo;  // Modo automático: manda el nivel
    ELSE
        SelBomba := btnManual;  // Modo manual: manda el botón
    END_IF;

END_FUNCTION
```