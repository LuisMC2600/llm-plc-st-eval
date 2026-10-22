```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; // Selector de modo de operación
    estadoSeguro : BOOL; // Indica si es seguro cambiar de modo
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos automáticos para los actuadores
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos manuales para los actuadores
    idxForzado : INT; // Índice del actuador a forzar en modo mantenimiento
    valorForzado : BOOL; // Valor a forzar en el actuador seleccionado
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT; // Modo de operación actual
    actuador : ARRAY[0..7] OF BOOL; // Estados de los actuadores
END_VAR

VAR
    modoPendiente : INT; // Modo pendiente de activación
    confirmarForzadoAnt : BOOL; // Estado anterior de confirmarForzado
    forzadoActivo : ARRAY[0..7] OF BOOL; // Indica si un actuador está forzado
END_VAR

// Inicialización
modoActivo := 1; // Modo inicial: manual
modoPendiente := 1;
confirmarForzadoAnt := FALSE;

// Lógica de control de modos
IF estadoSeguro THEN
    // Cambiar modo si el selector está en un rango válido
    IF (selector >= 0) AND (selector <= 2) THEN
        modoPendiente := selector;
    END_IF;
    modoActivo := modoPendiente;
ELSE
    // Si no está seguro, mantener el modo actual
    modoPendiente := modoActivo;
END_IF;

// Comportamiento según el modo activo
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
        // Apagar todos los actuadores si estadoSeguro se desactiva
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
                forzadoActivo[i] := FALSE;
            END_FOR;
        ELSE
            // Gestionar forzados
            IF (NOT confirmarForzadoAnt) AND confirmarForzado THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado;
                    forzadoActivo[idxForzado] := TRUE;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

// Actualizar estado anterior de confirmarForzado
confirmarForzadoAnt := confirmarForzado;

// Al salir del modo mantenimiento, anular todos los forzados
IF modoActivo <> 2 THEN
    FOR i := 0 TO 7 DO
        forzadoActivo[i] := FALSE;
    END_FOR;
END_IF;

END_FUNCTION_BLOCK
```