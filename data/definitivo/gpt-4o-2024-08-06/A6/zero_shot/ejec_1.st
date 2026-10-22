```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; // Selector de modo de operación
    estadoSeguro : BOOL; // Indica si es seguro cambiar de modo
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos en modo automático
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos en modo manual
    idxForzado : INT; // Índice del actuador a forzar
    valorForzado : BOOL; // Valor a forzar en el actuador
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT; // Modo de operación activo
    actuador : ARRAY[0..7] OF BOOL; // Estado de los actuadores
END_VAR

VAR
    modoPendiente : INT; // Modo pendiente de aplicar
    confirmarForzadoAnt : BOOL; // Estado anterior de confirmarForzado
    forzadoActivo : ARRAY[0..7] OF BOOL; // Indica si un actuador está forzado
END_VAR

// Inicialización
modoActivo := 1; // Inicia en modo manual
modoPendiente := 1; // Modo pendiente inicial
confirmarForzadoAnt := FALSE; // Estado inicial de confirmarForzado

// Gestión de modos
IF estadoSeguro THEN
    // Cambiar modo si el selector es válido
    IF (selector >= 0) AND (selector <= 2) THEN
        modoPendiente := selector;
    END_IF;
    modoActivo := modoPendiente;
ELSE
    // Si no es seguro, mantener el modo actual
    modoPendiente := modoActivo;
END_IF;

// Comportamiento según el modo activo
CASE modoActivo OF
    0: // Modo automático
        actuador := cmdAuto;
    1: // Modo manual
        actuador := cmdManual;
    2: // Modo mantenimiento
        // Apagar todos los actuadores si estadoSeguro es FALSE
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
                forzadoActivo[i] := FALSE;
            END_FOR;
        ELSE
            // Gestionar forzado
            IF (NOT confirmarForzadoAnt) AND confirmarForzado THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado;
                    forzadoActivo[idxForzado] := TRUE;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

// Actualizar el estado anterior de confirmarForzado
confirmarForzadoAnt := confirmarForzado;

// Al salir del modo mantenimiento, anular todos los forzados
IF modoActivo <> 2 THEN
    FOR i := 0 TO 7 DO
        forzadoActivo[i] := FALSE;
    END_FOR;
END_IF;

END_FUNCTION_BLOCK
```