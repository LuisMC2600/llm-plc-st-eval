FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0: Auto, 1: Manual, 2: Mantenimiento *)
    estadoSeguro : BOOL; (* Condicion para permitir cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automatico *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Indice del actuador a forzar (0-7) *)
    valorForzado : BOOL; (* Valor a aplicar en el forzado *)
    confirmarForzado : BOOL; (* Transicion para aplicar el forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo de operacion vigente *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado final de los actuadores *)
END_VAR
VAR
    modoInterno : INT := 1; (* El modo inicial es manual (1) *)
    rTrigConfirmar : R_TRIG; (* Detector de flanco para confirmar forzado *)
    modoMantenimientoPrevio : BOOL := FALSE; (* Marca para detectar inicio de mantenimiento *)
    i : INT; (* Variable para iteraciones *)
END_VAR

(* Gestion del cambio de modo de operacion *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        modoInterno := selector;
    END_IF;
END_IF;
modoActivo := modoInterno;

(* Deteccion del flanco de subida para forzar actuadores *)
rTrigConfirmar(CLK := confirmarForzado);

(* Control de actuadores segun el modo vigente *)
CASE modoInterno OF
    0: (* Modo Automatico *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
        modoMantenimientoPrevio := FALSE;

    1: (* Modo Manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
        modoMantenimientoPrevio := FALSE;

    2: (* Modo Mantenimiento *)
        (* Al entrar al modo o si se pierde el estado seguro, se apagan todos los actuadores *)
        IF NOT modoMantenimientoPrevio OR NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;

        (* Si hay estado seguro y se confirma el forzado, se aplica al indice valido *)
        IF estadoSeguro AND rTrigConfirmar.Q THEN
            IF idxForzado >= 0 AND idxForzado <= 7 THEN
                actuador[idxForzado] := valorForzado;
            END_IF;
        END_IF;
        
        modoMantenimientoPrevio := TRUE;
END_CASE;
END_FUNCTION_BLOCK