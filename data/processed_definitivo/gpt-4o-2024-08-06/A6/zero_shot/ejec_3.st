FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; // Selector de modo de operación
    estadoSeguro : BOOL; // Indica si el estado es seguro para cambiar de modo
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos automáticos para los actuadores
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos manuales para los actuadores
    idxForzado : INT; // Índice del actuador a forzar
    valorForzado : BOOL; // Valor a forzar en el actuador
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT; // Modo de operación activo
    actuador : ARRAY[0..7] OF BOOL; // Estados de los actuadores
END_VAR

VAR
    modoPendiente : INT; // Modo pendiente de aplicar
    forzadoPrevio : BOOL; // Estado previo de confirmarForzado
    forzados : ARRAY[0..7] OF BOOL; // Estados forzados de los actuadores
END_VAR

// Inicialización
modoActivo := 1; // Modo inicial es manual
modoPendiente := 1; // Modo pendiente inicial es manual
forzadoPrevio := FALSE; // Estado previo de confirmarForzado

// Lógica de gestión de modos
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

// Lógica de control de actuadores según el modo activo
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
        // Apagar todos los actuadores si estadoSeguro no está activo
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
                forzados[i] := FALSE;
            END_FOR;
        ELSE
            // Aplicar forzados
            IF (confirmarForzado AND NOT forzadoPrevio) THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    forzados[idxForzado] := valorForzado;
                END_IF;
            END_IF;
            FOR i := 0 TO 7 DO
                actuador[i] := forzados[i];
            END_FOR;
        END_IF;
END_CASE;

// Actualizar el estado previo de confirmarForzado
forzadoPrevio := confirmarForzado;
END_FUNCTION_BLOCK