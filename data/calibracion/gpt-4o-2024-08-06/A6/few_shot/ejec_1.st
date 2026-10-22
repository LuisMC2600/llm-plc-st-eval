```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo *)
    estadoSeguro : BOOL; (* Estado de seguridad *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automático *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Índice de actuador a forzar *)
    valorForzado : BOOL; (* Valor a forzar en el actuador *)
    confirmarForzado : BOOL; (* Confirmación de forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo vigente *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    modoPendiente : INT; (* Modo pendiente de activación *)
    confirmarForzadoAnt : BOOL; (* Estado anterior de confirmarForzado *)
    forzadoActivo : ARRAY[0..7] OF BOOL; (* Estado de forzados en mantenimiento *)
END_VAR

(* Inicialización del modo vigente a manual *)
IF NOT estadoSeguro THEN
    modoActivo := 1;
ELSE
    IF (selector >= 0) AND (selector <= 2) THEN
        modoPendiente := selector;
    END_IF;
    
    IF estadoSeguro THEN
        modoActivo := modoPendiente;
    END_IF;
END_IF;

(* Gestión de actuadores según el modo activo *)
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
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
                forzadoActivo[i] := FALSE;
            END_FOR;
        ELSE
            IF (confirmarForzado AND NOT confirmarForzadoAnt) THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado;
                    forzadoActivo[idxForzado] := TRUE;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

(* Actualización del estado anterior de confirmarForzado *)
confirmarForzadoAnt := confirmarForzado;
END_FUNCTION_BLOCK
```