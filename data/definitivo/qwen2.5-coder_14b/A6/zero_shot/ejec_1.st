```structured-text
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT;          // Selector de modo (0: automático, 1: manual, 2: mantenimiento)
    estadoSeguro : BOOL;      // Estado de seguridad activo/inactivo
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos automáticos para los actuadores
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos manuales para los actuadores
    idxForzado : INT;        // Índice del actuador a forzar
    valorForzado : BOOL;     // Valor a forzar en el actuador
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT;        // Modo activo (0: automático, 1: manual, 2: mantenimiento)
    actuador : ARRAY[0..7] OF BOOL; // Estado de los actuadores
END_VAR

VAR
    modoVigente : INT := 1;  // Modo vigente inicializado a manual (1)
    forzado : ARRAY[0..7] OF BOOL; // Estado de forzado de los actuadores
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

    // Manejo de los actuadores según el modo activo
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
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
            IF confirmarForzado THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                    forzado[idxForzado] := TRUE;
                END_IF;
            END_IF;
            IF NOT estadoSeguro THEN
                FOR i := 0 TO 7 DO
                    forzado[i] := FALSE;
                END_FOR;
            END_IF;
    END_CASE;

    // Anular forzados al salir del modo mantenimiento
    IF modoActivo <> 2 THEN
        FOR i := 0 TO 7 DO
            forzado[i] := FALSE;
        END_FOR;
    END_IF;
END_METHOD

// Llamada al método Update en cada ciclo
Update();
END_FUNCTION_BLOCK
```