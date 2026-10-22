FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; // Selector de modo de operación
    estadoSeguro : BOOL; // Indica si es seguro cambiar de modo
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos automáticos para los actuadores
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos manuales para los actuadores
    idxForzado : INT; // Índice del actuador a forzar
    valorForzado : BOOL; // Valor a forzar en el actuador
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT; // Modo de operación actual
    actuador : ARRAY[0..7] OF BOOL; // Estado de los actuadores
END_VAR

VAR
    modoPendiente : INT; // Modo pendiente de activación
    confirmarForzadoAnt : BOOL; // Estado anterior de confirmarForzado
    forzados : ARRAY[0..7] OF BOOL; // Estados forzados de los actuadores
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
        // Apagar todos los actuadores si estadoSeguro se desactiva
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                forzados[i] := FALSE;
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            // Gestionar forzados
            IF (confirmarForzado AND NOT confirmarForzadoAnt) THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    forzados[idxForzado] := valorForzado;
                END_IF;
            END_IF;
            // Aplicar forzados
            FOR i := 0 TO 7 DO
                actuador[i] := forzados[i];
            END_FOR;
        END_IF;
END_CASE;

// Actualizar estado anterior de confirmarForzado
confirmarForzadoAnt := confirmarForzado;

END_FUNCTION_BLOCK