```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo: 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro : BOOL; (* Indica si es seguro cambiar de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automático *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Índice del actuador a forzar en modo mantenimiento *)
    valorForzado : BOOL; (* Valor a forzar en el actuador seleccionado *)
    confirmarForzado : BOOL; (* Confirmación de forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo vigente de operación *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    modoPendiente : INT; (* Modo pendiente de aplicar cuando estadoSeguro sea TRUE *)
    confirmarForzadoAnt : BOOL; (* Estado anterior de confirmarForzado *)
    forzados : ARRAY[0..7] OF BOOL; (* Estados forzados de los actuadores en modo mantenimiento *)
END_VAR

(* Inicialización: el modo vigente al arrancar es manual *)
IF NOT estadoSeguro THEN
    modoActivo := 1;
END_IF

(* Gestión de cambio de modo *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        modoPendiente := selector;
    END_IF
    modoActivo := modoPendiente;
END_IF

(* Comportamiento según el modo activo *)
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
                forzados[i] := FALSE;
                actuador[i] := FALSE;
            END_FOR
        ELSE
            IF confirmarForzado AND NOT confirmarForzadoAnt THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    forzados[idxForzado] := valorForzado;
                END_IF
            END_IF
            FOR i := 0 TO 7 DO
                actuador[i] := forzados[i];
            END_FOR
        END_IF
END_CASE

(* Actualización del estado anterior de confirmarForzado *)
confirmarForzadoAnt := confirmarForzado;

END_FUNCTION_BLOCK
```