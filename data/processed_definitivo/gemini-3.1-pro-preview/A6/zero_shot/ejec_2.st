FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0: Auto, 1: Manual, 2: Mantenimiento *)
    estadoSeguro : BOOL; (* Condición para permitir cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automático *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Índice del actuador a forzar (0-7) *)
    valorForzado : BOOL; (* Valor a aplicar al actuador forzado *)
    confirmarForzado : BOOL; (* Flanco de subida aplica el forzado *)
END_VAR

VAR_OUTPUT
    modoActivo : INT := 1; (* Inicia en modo Manual (1) *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los 8 actuadores *)
END_VAR

VAR
    prevConfirmarForzado : BOOL := FALSE; (* Memoria para detectar flanco *)
    flancoConfirmar : BOOL;
    modoAnterior : INT := 1; (* Memoria para detectar cambio de modo *)
    i : INT; (* Índice para bucles *)
END_VAR

(* 1. Gestión del cambio de modo de operación *)
IF estadoSeguro THEN
    IF (selector >= 0) AND (selector <= 2) THEN
        modoActivo := selector;
    END_IF;
END_IF;

(* 2. Detección de flanco de subida para confirmarForzado *)
flancoConfirmar := confirmarForzado AND NOT prevConfirmarForzado;
prevConfirmarForzado := confirmarForzado;

(* 3. Inicialización al entrar en modo Mantenimiento *)
IF (modoActivo = 2) AND (modoAnterior <> 2) THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;

(* 4. Lógica de control de actuadores según el modo activo *)
CASE modoActivo OF
    0: (* Modo Automático *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
        
    1: (* Modo Manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
        
    2: (* Modo Mantenimiento *)
        IF NOT estadoSeguro THEN
            (* Si se pierde el estado seguro, se anulan forzados y se apaga todo *)
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            (* Aplicar forzado individual si hay flanco y el índice es válido *)
            IF flancoConfirmar THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
END_CASE;

(* 5. Actualizar memoria del modo para el siguiente ciclo *)
modoAnterior := modoActivo;

END_FUNCTION_BLOCK