FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro : BOOL; (* Condicion para permitir cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automatico *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Indice del actuador a forzar (0-7) *)
    valorForzado : BOOL; (* Valor a forzar en mantenimiento *)
    confirmarForzado : BOOL; (* Flanco de subida para aplicar forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT := 1; (* Modo vigente, arranca en manual (1) *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los 8 actuadores *)
END_VAR
VAR
    trigConfirmar : R_TRIG; (* Detector de flanco para el forzado *)
    i : INT; (* Variable para bucles *)
    modoAnterior : INT := 1; (* Memoria para detectar flanco de modo *)
END_VAR

(* Actualizacion de modo solo si hay estado seguro y selector valido *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        modoActivo := selector;
    END_IF;
END_IF;

(* Deteccion de flanco del boton de confirmacion *)
trigConfirmar(CLK := confirmarForzado);

(* Al entrar a modo mantenimiento, todos los actuadores parten apagados *)
IF modoActivo = 2 AND modoAnterior <> 2 THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;
modoAnterior := modoActivo;

(* Logica de actuadores segun el modo activo *)
CASE modoActivo OF
    0: (* Automatico *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
        
    1: (* Manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
        
    2: (* Mantenimiento *)
        IF NOT estadoSeguro THEN
            (* Si se pierde estado seguro, se anulan forzados y apagan actuadores *)
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            (* Aplicar forzado individual si el indice es valido y hay flanco *)
            IF trigConfirmar.Q THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
END_CASE;
END_FUNCTION_BLOCK