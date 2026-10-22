FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo *)
    estadoSeguro : BOOL; (* Estado seguro *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos automáticos *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos manuales *)
    idxForzado : INT; (* Índice del actuador forzado *)
    valorForzado : BOOL; (* Valor del actuador forzado *)
    confirmarForzado : BOOL; (* Confirmación de forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo activo *)
    actuador : ARRAY[0..7] OF BOOL; (* Actuadores *)
END_VAR
VAR
    modoAnterior : INT := 1; (* Modo anterior, inicializado a manual *)
    forzado : ARRAY[0..7] OF BOOL := [FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE]; (* Estado de forzado *)
END_VAR

(* Gestión de modos *)
IF estadoSeguro THEN
    CASE selector OF
        0..2: modoActivo := selector;
        ELSE modoActivo := modoAnterior;
    END_CASE
ELSE
    modoActivo := modoAnterior;
END_IF

(* Actualización del modo anterior *)
IF estadoSeguro THEN
    modoAnterior := modoActivo;
END_IF

(* Gestión de actuadores según el modo *)
CASE modoActivo OF
    0: (* Modo automático *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR
    1: (* Modo manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR
    2: (* Modo mantenimiento *)
        FOR i := 0 TO 7 DO
            actuador[i] := FALSE;
        END_FOR
        IF confirmarForzado THEN
            IF idxForzado >= 0 AND idxForzado <= 7 THEN
                actuador[idxForzado] := valorForzado;
                forzado[idxForzado] := TRUE;
            END_IF
        END_IF
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                forzado[i] := FALSE;
            END_FOR
        END_IF
END_CASE

(* Anulación de forzados al salir del modo mantenimiento *)
IF modoActivo <> 2 THEN
    FOR i := 0 TO 7 DO
        forzado[i] := FALSE;
    END_FOR
END_IF

END_FUNCTION_BLOCK