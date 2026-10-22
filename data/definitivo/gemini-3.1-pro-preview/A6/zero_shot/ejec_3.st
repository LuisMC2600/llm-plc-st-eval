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
    modoActivo : INT := 1; // Inicializado en modo manual (1)
    actuador : ARRAY[0..7] OF BOOL;
END_VAR

VAR
    prevModoActivo : INT := 1;
    prevConfirmarForzado : BOOL := FALSE;
    flancoConfirmar : BOOL;
    i : INT;
END_VAR

// 1. Gestión del cambio de modo de operación
IF estadoSeguro THEN
    // Solo se aceptan valores válidos (0=Auto, 1=Manual, 2=Mantenimiento)
    IF selector >= 0 AND selector <= 2 THEN
        modoActivo := selector;
    END_IF;
END_IF;

// 2. Detección de flanco de subida para confirmarForzado
flancoConfirmar := confirmarForzado AND NOT prevConfirmarForzado;
prevConfirmarForzado := confirmarForzado;

// 3. Lógica de control de los actuadores según el modo activo
CASE modoActivo OF
    
    0: // MODO AUTOMÁTICO
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
        
    1: // MODO MANUAL
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
        
    2: // MODO MANTENIMIENTO
        // Al entrar al modo mantenimiento, todos los actuadores parten apagados
        IF prevModoActivo <> 2 THEN
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
            // Si hay estado seguro y flanco de confirmación, aplicar forzado si el índice es válido
            IF flancoConfirmar THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
        
END_CASE;

// 4. Actualización del estado previo del modo
prevModoActivo := modoActivo;

END_FUNCTION_BLOCK
```