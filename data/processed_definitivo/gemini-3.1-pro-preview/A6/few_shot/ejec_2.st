FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro : BOOL; (* Condicion para permitir cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos modo automatico *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos modo manual *)
    idxForzado : INT; (* Indice del actuador a forzar (0..7) *)
    valorForzado : BOOL; (* Valor a aplicar en el forzado *)
    confirmarForzado : BOOL; (* Flanco de subida confirma el forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT := 1; (* Modo vigente, arranca en manual (1) *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los 8 actuadores *)
END_VAR
VAR
    trigConfirmar : R_TRIG; (* Detector de flanco para confirmarForzado *)
    modoAnterior : INT := 1; (* Memoria para detectar transiciones de modo *)
    i : INT; (* Variable de control para bucles *)
END_VAR

(* Lectura del flanco de confirmacion de forzado *)
trigConfirmar(CLK := confirmarForzado);

(* Cambio de modo solo si hay estado seguro y el selector es valido *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        modoActivo := selector;
    END_IF;
END_IF;

(* Al entrar en modo mantenimiento, los actuadores parten apagados *)
IF modoActivo = 2 AND modoAnterior <> 2 THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;
modoAnterior := modoActivo;

(* Logica de control de actuadores segun el modo vigente *)
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
            (* Si se pierde la seguridad, se anulan forzados y se apaga todo *)
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            (* Forzado individual de actuadores al confirmar *)
            IF trigConfirmar.Q THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
END_CASE;
(* Nota: Al salir de mantenimiento hacia Auto/Manual, los arreglos cmdAuto/cmdManual 
   sobrescriben inmediatamente las salidas, anulando asi los forzados previos. *)
END_FUNCTION_BLOCK