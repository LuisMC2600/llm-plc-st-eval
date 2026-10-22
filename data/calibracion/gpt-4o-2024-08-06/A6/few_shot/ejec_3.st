```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo: 0=automático, 1=manual, 2=mantenimiento *)
    estadoSeguro : BOOL; (* Estado seguro para permitir cambios de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos automáticos para actuadores *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos manuales para actuadores *)
    idxForzado : INT; (* Índice del actuador a forzar en modo mantenimiento *)
    valorForzado : BOOL; (* Valor a forzar en el actuador seleccionado *)
    confirmarForzado : BOOL; (* Confirmación de forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo vigente de operación *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    modoPendiente : INT; (* Modo pendiente de aplicar cuando estadoSeguro esté activo *)
    confirmarForzadoAnt : BOOL; (* Estado anterior de confirmarForzado *)
END_VAR

(* Inicialización del modo activo en manual al arrancar el bloque *)
IF NOT estadoSeguro THEN
    modoPendiente := modoActivo; (* Mantener el modo pendiente actual *)
ELSE
    IF (selector >= 0) AND (selector <= 2) THEN
        modoPendiente := selector; (* Actualizar modo pendiente si el selector es válido *)
    END_IF
END_IF

(* Aplicar el modo pendiente si estadoSeguro está activo *)
IF estadoSeguro THEN
    modoActivo := modoPendiente;
END_IF

(* Gestión de actuadores según el modo activo *)
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
                actuador[i] := FALSE; (* Apagar todos los actuadores si estadoSeguro no está activo *)
            END_FOR
        ELSE
            IF (confirmarForzado AND NOT confirmarForzadoAnt) THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado; (* Forzar actuador si el índice es válido *)
                END_IF
            END_IF
        END_IF
END_CASE

(* Actualizar el estado anterior de confirmarForzado *)
confirmarForzadoAnt := confirmarForzado;
END_FUNCTION_BLOCK
```