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
    prevConfirmar : BOOL;
    flancoConfirmar : BOOL;
    prevModo : INT := 1;
    i : INT;
END_VAR

// Detección de flanco de subida para la señal de confirmación de forzado
flancoConfirmar := confirmarForzado AND NOT prevConfirmar;
prevConfirmar := confirmarForzado;

// Gestión de cambio de modo de operación (solo si hay estado seguro y el selector es válido)
IF estadoSeguro THEN
    IF (selector >= 0) AND (selector <= 2) THEN
        modoActivo := selector;
    END_IF;
END_IF;

// Lógica de control de actuadores según el modo activo
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
        // Al entrar al modo mantenimiento, todos los actuadores parten apagados
        IF prevModo <> 2 THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;
        
        // Si se pierde el estado seguro durante el mantenimiento, se anulan los forzados
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            // Aplicar forzado individual en flanco de subida si el índice está en rango
            IF flancoConfirmar THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

// Actualizar el registro del modo previo para evaluar transiciones en el siguiente ciclo
prevModo := modoActivo;

END_FUNCTION_BLOCK
```