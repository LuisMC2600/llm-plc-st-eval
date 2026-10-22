```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT;          // Selector de modo (0: Automático, 1: Manual, 2: Mantenimiento)
    estadoSeguro : BOOL;     // Estado de seguridad activo/inactivo
    cmdAuto : ARRAY[0..7] OF BOOL; // Comandos para actuadores en modo automático
    cmdManual : ARRAY[0..7] OF BOOL; // Comandos para actuadores en modo manual
    idxForzado : INT;        // Índice del actuador a forzar en modo mantenimiento
    valorForzado : BOOL;     // Valor a forzar en el actuador seleccionado
    confirmarForzado : BOOL; // Confirmación de forzado
END_VAR

VAR_OUTPUT
    modoActivo : INT;        // Modo de operación activo
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
        modoVigente := modoVigente;
    ELSE
        modoVigente := selector;
    END_IF;

    // Aplicar el modo si estadoSeguro está activo
    IF estadoSeguro THEN
        modoActivo := modoVigente;
    END_IF;

    // Manejo de los modos
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
                actuador[i] := FALSE; // Apagar todos los actuadores
            END_FOR;
            IF confirmarForzado THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                    forzado[idxForzado] := TRUE;
                END_IF;
            END_IF;
    END_CASE;

    // Anular forzados si estadoSeguro se desactiva o se sale del modo mantenimiento
    IF NOT estadoSeguro OR modoActivo <> 2 THEN
        FOR i := 0 TO 7 DO
            forzado[i] := FALSE;
        END_FOR;
    END_IF;

END_METHOD

END_FUNCTION_BLOCK
```