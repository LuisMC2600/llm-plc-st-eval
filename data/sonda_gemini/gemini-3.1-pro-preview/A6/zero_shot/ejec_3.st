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
    modoActivo : INT := 1; // El modo vigente al arrancar es manual (1)
    actuador : ARRAY[0..7] OF BOOL;
END_VAR

VAR
    i : INT;
    modoAnterior : INT := 1;
    prevConfirmar : BOOL := FALSE;
    flancoConfirmar : BOOL;
END_VAR

// 1. Gestión de cambio de modo de operación
IF estadoSeguro THEN
    // Solo se aceptan valores válidos (0=Auto, 1=Manual, 2=Mantenimiento)
    IF selector >= 0 AND selector <= 2 THEN
        modoActivo := selector;
    END_IF;
END_IF;

// 2. Detección de flanco de subida para la señal de confirmación
flancoConfirmar := confirmarForzado AND NOT prevConfirmar;
prevConfirmar := confirmarForzado;

// 3. Inicialización al entrar en modo mantenimiento (apagar todos)
IF modoActivo = 2 AND modoAnterior <> 2 THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;

// 4. Lógica de control de actuadores según el modo activo
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
            // Si se pierde el estado seguro durante el mantenimiento, apagar todo
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            // Si hay flanco de subida y el índice está en rango, aplicar forzado
            IF flancoConfirmar THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

// 5. Actualizar el modo anterior para el siguiente ciclo de escaneo
modoAnterior := modoActivo;

END_FUNCTION_BLOCK
```