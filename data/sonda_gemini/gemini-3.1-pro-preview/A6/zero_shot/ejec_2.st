```iecst
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0: Auto, 1: Manual, 2: Mantenimiento *)
    estadoSeguro : BOOL; (* Condición para permitir cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automático *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo manual *)
    idxForzado : INT; (* Índice del actuador a forzar (0-7) *)
    valorForzado : BOOL; (* Valor a aplicar al actuador forzado *)
    confirmarForzado : BOOL; (* Señal para aplicar el forzado *)
END_VAR

VAR_OUTPUT
    modoActivo : INT := 1; (* Modo vigente, inicializado en Manual (1) *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los 8 actuadores *)
END_VAR

VAR
    trigConfirmar : R_TRIG; (* Detector de flanco de subida para confirmarForzado *)
    modoAnterior : INT := 1; (* Memoria del modo en el ciclo anterior *)
    i : INT; (* Variable para bucles *)
END_VAR

(* 1. Gestión del cambio de modo de operación *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        modoActivo := selector;
    END_IF;
END_IF;

(* 2. Detección de flanco para la confirmación de forzado *)
trigConfirmar(CLK := confirmarForzado);

(* 3. Lógica de control de actuadores según el modo activo *)
CASE modoActivo OF
    
    0: (* MODO AUTOMÁTICO *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
        
    1: (* MODO MANUAL *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
        
    2: (* MODO MANTENIMIENTO *)
        (* Al entrar al modo mantenimiento, apagar todos los actuadores *)
        IF modoAnterior <> 2 THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;
        
        (* Si se pierde el estado seguro, anular forzados y apagar actuadores *)
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            (* Aplicar forzado individual en flanco de subida si el índice es válido *)
            IF trigConfirmar.Q THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
            END_IF;
        END_IF;
        
END_CASE;

(* 4. Actualización de la memoria del modo para el próximo ciclo *)
(* Nota: Al salir de mantenimiento (modoActivo pasa a 0 o 1), los forzados se anulan 
   automáticamente al sobrescribirse el array actuador con cmdAuto o cmdManual *)
modoAnterior := modoActivo;

END_FUNCTION_BLOCK
```