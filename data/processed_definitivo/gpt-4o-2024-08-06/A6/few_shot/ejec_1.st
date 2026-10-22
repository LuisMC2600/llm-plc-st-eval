FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo: 0=Automático, 1=Manual, 2=Mantenimiento *)
    estadoSeguro : BOOL; (* Indica si el estado es seguro para cambiar de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos automáticos para actuadores *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos manuales para actuadores *)
    idxForzado : INT; (* Índice del actuador a forzar en modo mantenimiento *)
    valorForzado : BOOL; (* Valor a forzar en el actuador seleccionado *)
    confirmarForzado : BOOL; (* Confirmación de forzado de actuador *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo de operación vigente *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    modoSolicitado : INT := 1; (* Modo solicitado, inicia en Manual *)
    confirmarForzadoAnt : BOOL; (* Estado anterior de confirmarForzado *)
END_VAR

(* Gestión de cambio de modo *)
IF estadoSeguro THEN
    IF (selector >= 0) AND (selector <= 2) THEN
        modoSolicitado := selector;
    END_IF
END_IF

IF estadoSeguro THEN
    modoActivo := modoSolicitado;
END_IF

(* Control de actuadores según el modo activo *)
CASE modoActivo OF
    0: (* Modo Automático *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR
    1: (* Modo Manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR
    2: (* Modo Mantenimiento *)
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE; (* Apagar todos los actuadores si no es seguro *)
            END_FOR
        ELSE
            IF (confirmarForzado AND NOT confirmarForzadoAnt) THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado; (* Forzar actuador seleccionado *)
                END_IF
            END_IF
        END_IF
END_CASE

(* Actualizar estado anterior de confirmarForzado *)
confirmarForzadoAnt := confirmarForzado;
END_FUNCTION_BLOCK