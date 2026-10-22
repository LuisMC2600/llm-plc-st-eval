```iecst
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT;
    estadoSeguro : BOOL;
    cmdAuto : ARRAY[0..7] OF BOOL;
    cmdManual : ARRAY[0..7] OF BOOL;
    idxForzado : INT;
    valorForzado : BOOL;
    confirmarForzado : BOOL;
END_VAR

VAR_OUTPUT
    modoActivo : INT := 1; // Inicializa en modo manual (1) por defecto
    actuador : ARRAY[0..7] OF BOOL;
END_VAR

VAR
    prevConfirmarForzado : BOOL := FALSE;
    flancoConfirmar : BOOL;
    i : INT;
END_VAR

// Detección de flanco de subida para la señal de confirmación de forzado
flancoConfirmar := confirmarForzado AND NOT prevConfirmarForzado;
prevConfirmarForzado := confirmarForzado;

// Gestión de cambio de modo de operación
IF estadoSeguro THEN
    // Solo se aceptan valores válidos (0=Auto, 1=Manual, 2=Mantenimiento)
    IF (selector >= 0) AND (selector <= 2) THEN
        IF modoActivo <> selector THEN
            modoActivo := selector;
            
            // Al entrar en modo mantenimiento, todos los actuadores parten apagados
            IF modoActivo = 2 THEN
                FOR i := 0 TO 7 DO
                    actuador[i] := FALSE;
                END_FOR;
            END_IF;
        END_IF;
    END_IF;
END_IF;

// Lógica de control de los actuadores según el modo vigente
CASE modoActivo OF
    0: // Modo Automático
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    1: // Modo Manual
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    2: // Modo Mantenimiento
        IF NOT estadoSeguro THEN
            // Si se pierde el estado seguro durante el mantenimiento, se anulan los forzados
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            // Si hay estado seguro, se permite forzar actuadores individualmente
            IF flancoConfirmar THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK
```