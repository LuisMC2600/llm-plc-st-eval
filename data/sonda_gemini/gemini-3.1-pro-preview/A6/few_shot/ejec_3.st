FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0: Auto, 1: Manual, 2: Mantenimiento *)
    estadoSeguro : BOOL; (* Condicion para aceptar cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automatico *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Indice del actuador a forzar (0-7) *)
    valorForzado : BOOL; (* Valor a forzar en mantenimiento *)
    confirmarForzado : BOOL; (* Flanco de subida aplica el forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT := 1; (* Modo vigente, arranca en manual (1) *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    trigConfirmar : R_TRIG; (* Detector de flanco para confirmar forzado *)
    modoAnterior : INT := 1; (* Memoria para detectar transiciones de modo *)
    i : INT; (* Indice para bucles *)
END_VAR

(* Actualizacion del detector de flanco *)
trigConfirmar(CLK := confirmarForzado);

(* Gestion de cambio de modo *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        modoActivo := selector;
    END_IF;
END_IF;

(* Deteccion de entrada al modo mantenimiento para apagar actuadores *)
IF modoActivo = 2 AND modoAnterior <> 2 THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;
modoAnterior := modoActivo;

(* Logica de control de actuadores segun el modo activo *)
CASE modoActivo OF
    0: (* Modo Automatico *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
        
    1: (* Modo Manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
        
    2: (* Modo Mantenimiento *)
        IF NOT estadoSeguro THEN
            (* Anular forzados si se pierde el estado seguro *)
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSIF trigConfirmar.Q THEN
            (* Aplicar forzado si el indice esta en rango *)
            IF idxForzado >= 0 AND idxForzado <= 7 THEN
                actuador[idxForzado] := valorForzado;
            END_IF;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK