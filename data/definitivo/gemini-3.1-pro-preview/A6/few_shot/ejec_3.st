FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro : BOOL; (* Condicion para cambiar de modo o mantener forzados *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automatico *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Indice del actuador a forzar (0-7) *)
    valorForzado : BOOL; (* Valor a aplicar en el forzado *)
    confirmarForzado : BOOL; (* Flanco de subida para aplicar forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT := 1; (* Modo vigente, inicia en manual (1) *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los 8 actuadores *)
END_VAR
VAR
    rTrigConfirmar : R_TRIG; (* Detector de flanco para confirmar forzado *)
    i : INT; (* Variable para bucles *)
    modoAnterior : INT := 1; (* Memoria para detectar cambios de modo *)
END_VAR

(* 1. Gestion del cambio de modo *)
IF estadoSeguro THEN
    IF (selector >= 0) AND (selector <= 2) THEN
        modoActivo := selector;
    END_IF;
END_IF;

(* 2. Deteccion de flanco para la confirmacion del forzado *)
rTrigConfirmar(CLK := confirmarForzado);

(* 3. Inicializacion al entrar al modo mantenimiento *)
IF (modoActivo = 2) AND (modoAnterior <> 2) THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;
modoAnterior := modoActivo;

(* 4. Control de actuadores segun el modo activo *)
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
            (* Si se pierde la seguridad, se anulan los forzados *)
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSIF rTrigConfirmar.Q THEN
            (* Aplicar forzado individual si el indice es valido *)
            IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                actuador[idxForzado] := valorForzado;
            END_IF;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK