```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; // Selector de modo: 0 = automático, 1 = manual, 2 = mantenimiento
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
modoPendiente := 1; // Modo pendiente inicial: manual
confirmarForzadoAnt := FALSE; // Estado inicial de confirmarForzado

// Gestión de modos
IF estadoSeguro THEN
    // Cambiar modo si el selector es válido
    IF (selector >= 0) AND (selector <= 2) THEN
        modoPendiente := selector;
    END_IF;
    modoActivo := modoPendiente;
END_IF;

// Comportamiento según el modo activo
CASE modoActivo OF
    0: // Modo automático
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
    1: // Modo manual
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
    2: // Modo mantenimiento
        // Apagar actuadores si estadoSeguro se desactiva
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
                forzadoActivo[i] := FALSE;
            END_FOR;
        ELSE
            // Gestionar forzado de actuadores
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
```
