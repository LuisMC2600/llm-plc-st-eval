```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo *)
    estadoSeguro : BOOL; (* Estado seguro para cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automático *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Índice de actuador a forzar *)
    valorForzado : BOOL; (* Valor a forzar en el actuador *)
    confirmarForzado : BOOL; (* Confirmar forzado de actuador *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo de operación vigente *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    modoSeleccionado : INT := 1; (* Modo seleccionado, inicia en manual *)
    confirmarForzadoAnt : BOOL; (* Estado anterior de confirmarForzado *)
    forzadoActivo : ARRAY[0..7] OF BOOL; (* Estado de forzado de actuadores *)
END_VAR

(* Gestión de cambio de modo *)
IF estadoSeguro THEN
    IF (selector >= 0) AND (selector <= 2) THEN
        modoSeleccionado := selector;
    END_IF
END_IF

(* Actualización del modo activo *)
modoActivo := modoSeleccionado;

(* Control de actuadores según el modo activo *)
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
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                forzadoActivo[i] := FALSE;
                actuador[i] := FALSE;
            END_FOR
        ELSE
            IF (confirmarForzado AND NOT confirmarForzadoAnt) THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    forzadoActivo[idxForzado] := valorForzado;
                END_IF
            END_IF
            FOR i := 0 TO 7 DO
                actuador[i] := forzadoActivo[i];
            END_FOR
        END_IF
END_CASE

(* Actualización del estado anterior de confirmarForzado *)
confirmarForzadoAnt := confirmarForzado;
END_FUNCTION_BLOCK
```