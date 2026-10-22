```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; // Selector de modo
    estadoSeguro : BOOL; // Estado seguro
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos automáticos
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos manuales
    idxForzado : INT; // Índice de actuador a forzar
    valorForzado : BOOL; // Valor a forzar
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT; // Modo activo actual
    actuador : ARRAY[0..7] OF BOOL; // Estado de los actuadores
END_VAR

VAR
    modoPendiente : INT; // Modo pendiente de cambio
    confirmarForzadoAnt : BOOL; // Estado anterior de confirmarForzado
    forzado : ARRAY[0..7] OF BOOL; // Estado de forzado de actuadores
END_VAR

// Inicialización
modoActivo := 1; // Modo inicial es manual
modoPendiente := 1; // Modo pendiente inicial es manual
confirmarForzadoAnt := FALSE; // Estado inicial de confirmarForzado

// Gestión de modos
IF estadoSeguro THEN
    // Cambiar modo si el selector es válido
    IF (selector >= 0) AND (selector <= 2) THEN
        modoPendiente := selector;
    END_IF;
    modoActivo := modoPendiente;
ELSE
    // Si no está en estado seguro, mantener el modo actual
    modoPendiente := modoActivo;
END_IF;

// Comportamiento según el modo activo
CASE modoActivo OF
    0: // Modo automático
        actuador := cmdAuto;
    1: // Modo manual
        actuador := cmdManual;
    2: // Modo mantenimiento
        // Anular forzados si estadoSeguro se desactiva
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                forzado[i] := FALSE;
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            // Gestionar forzados
            IF (NOT confirmarForzadoAnt) AND confirmarForzado THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    forzado[idxForzado] := TRUE;
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

// Actualizar estado anterior de confirmarForzado
confirmarForzadoAnt := confirmarForzado;
END_FUNCTION_BLOCK
```