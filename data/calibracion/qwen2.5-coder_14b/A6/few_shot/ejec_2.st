FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo *)
    estadoSeguro : BOOL; (* Estado seguro *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos automáticos para los actuadores *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos manuales para los actuadores *)
    idxForzado : INT; (* Índice del actuador a forzar *)
    valorForzado : BOOL; (* Valor a forzar en el actuador *)
    confirmarForzado : BOOL; (* Confirmación de forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo activo *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    modoAnterior : INT := 1; (* Modo anterior, inicializado a manual *)
    forzado : ARRAY[0..7] OF BOOL := [FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE]; (* Estado de forzado de los actuadores *)
END_VAR

(* Gestión de modos *)
IF estadoSeguro THEN
    CASE selector OF
        0: modoActivo := 0; (* Modo automático *)
        1: modoActivo := 1; (* Modo manual *)
        2: modoActivo := 2; (* Modo mantenimiento *)
        ELSE modoActivo := modoAnterior; (* Mantener modo anterior si selector fuera de rango *)
    END_CASE;
ELSE
    modoActivo := modoAnterior; (* Mantener modo anterior si no está seguro *)
END_IF;

(* Actualización del modo anterior *)
IF estadoSeguro THEN
    modoAnterior := modoActivo;
END_IF;

(* Gestión de actuadores según el modo *)
CASE modoActivo OF
    0: (* Modo automático *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
    1: (* Modo manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
    2: (* Modo mantenimiento *)
        FOR i := 0 TO 7 DO
            actuador[i] := FALSE; (* Apagar todos los actuadores *)
        END_FOR;
        IF confirmarForzado THEN
            IF idxForzado >= 0 AND idxForzado <= 7 THEN
                actuador[idxForzado] := valorForzado; (* Forzar el actuador seleccionado *)
                forzado[idxForzado] := TRUE; (* Marcar como forzado *)
            END_IF;
        END_IF;
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE; (* Anular forzado si no está seguro *)
                forzado[i] := FALSE;
            END_FOR;
        END_IF;
END_CASE;

(* Anular forzado al salir del modo mantenimiento *)
IF modoActivo <> 2 THEN
    FOR i := 0 TO 7 DO
        forzado[i] := FALSE;
    END_FOR;
END_IF;

END_FUNCTION_BLOCK