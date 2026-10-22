```iec
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT;          // Selector de modo (0: Automático, 1: Manual, 2: Mantenimiento)
    estadoSeguro : BOOL;      // Estado de seguridad activo/inactivo
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos automáticos para los actuadores
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos manuales para los actuadores
    idxForzado : INT;        // Índice del actuador a forzar (0-7)
    valorForzado : BOOL;     // Valor a forzar en el actuador
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT;         // Modo activo (0: Automático, 1: Manual, 2: Mantenimiento)
    actuador : ARRAY[0..7] OF BOOL; // Estado de los actuadores
END_VAR

VAR
    modoVigente : INT := 1;  // Modo vigente inicializado a Manual (1)
    forzado : ARRAY[0..7] OF BOOL; // Estado de forzado de los actuadores
    forzadoActivo : BOOL := FALSE; // Indica si hay algún forzado activo
END_VAR

METHOD Update : VOID
VAR
    i : INT;
END_VAR

    // Mantener el modo vigente si el selector está fuera de rango
    IF selector < 0 OR selector > 2 THEN
        modoActivo := modoVigente;
    ELSE
        modoActivo := selector;
    END_IF;

    // Cambiar el modo vigente solo si estadoSeguro está activo
    IF estadoSeguro THEN
        modoVigente := modoActivo;
    END_IF;

    // Actualizar los actuadores según el modo activo
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
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
            IF confirmarForzado THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                    forzado[idxForzado] := TRUE;
                    forzadoActivo := TRUE;
                END_IF;
            END_IF;
    END_CASE;

    // Anular los forzados si estadoSeguro se desactiva o se sale del modo mantenimiento
    IF NOT estadoSeguro OR modoActivo <> 2 THEN
        FOR i := 0 TO 7 DO
            forzado[i] := FALSE;
            actuador[i] := FALSE;
        END_FOR;
        forzadoActivo := FALSE;
    END_IF;

END_METHOD

END_FUNCTION_BLOCK
```