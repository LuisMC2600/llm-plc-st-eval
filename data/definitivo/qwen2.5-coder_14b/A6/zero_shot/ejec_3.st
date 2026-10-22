```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT;          // Selector de modo (0: automático, 1: manual, 2: mantenimiento)
    estadoSeguro : BOOL;      // Estado de seguridad activo/inactivo
    cmdAuto : ARRAY[0..7] OF BOOL;  // Comandos para modo automático
    cmdManual : ARRAY[0..7] OF BOOL;  // Comandos para modo manual
    idxForzado : INT;        // Índice del actuador a forzar en modo mantenimiento
    valorForzado : BOOL;      // Valor a forzar en el actuador seleccionado
    confirmarForzado : BOOL;  // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT;         // Modo de operación activo
    actuador : ARRAY[0..7] OF BOOL;  // Estado de los actuadores
END_VAR

VAR
    modoAnterior : INT;       // Modo anterior para comparación
    forzado : ARRAY[0..7] OF BOOL;  // Estado de forzado de los actuadores
END_VAR

// Inicialización en el arranque
IF NOT estadoSeguro THEN
    modoActivo := 1;  // Modo manual por defecto
ELSE
    modoAnterior := modoActivo;
    CASE selector OF
        0..2: modoActivo := selector;  // Cambio de modo si el selector está en un valor válido
        ELSE modoActivo := modoAnterior;  // Mantener modo anterior si el selector está fuera de rango
    END_CASE;
END_IF;

// Gestión de los actuadores según el modo
CASE modoActivo OF
    0:  // Modo automático
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
    1:  // Modo manual
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
    2:  // Modo mantenimiento
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
                forzado[i] := FALSE;
            END_FOR;
        ELSE
            IF confirmarForzado THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                    forzado[idxForzado] := TRUE;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

// Anulación de forzados al salir del modo mantenimiento
IF modoAnterior = 2 AND modoActivo <> 2 THEN
    FOR i := 0 TO 7 DO
        forzado[i] := FALSE;
    END_FOR;
END_IF;

// Anulación de forzados si estadoSeguro se desactiva durante el mantenimiento
IF modoActivo = 2 AND NOT estadoSeguro THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
        forzado[i] := FALSE;
    END_FOR;
END_IF;

modoAnterior := modoActivo;
END_FUNCTION_BLOCK
```