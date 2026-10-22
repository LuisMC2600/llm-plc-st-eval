```st
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector       : INT;                  (* Selector de modo: 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro   : BOOL;                 (* Permiso para cambiar modo y mantener forzados *)
    cmdAuto        : ARRAY[0..7] OF BOOL;  (* Comandos en modo automatico *)
    cmdManual      : ARRAY[0..7] OF BOOL;  (* Comandos en modo manual *)
    idxForzado     : INT;                  (* Indice del actuador a forzar (0-7) *)
    valorForzado   : BOOL;                 (* Valor a aplicar al actuador forzado *)
    confirmarForzado : BOOL;               (* Flanco ascendente aplica el forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT;                      (* Modo vigente: 0=Auto, 1=Manual, 2=Mantenimiento *)
    actuador   : ARRAY[0..7] OF BOOL;      (* Estado de los ocho actuadores *)
END_VAR
VAR
    prevConfirmar  : BOOL;                 (* Valor anterior de confirmarForzado para deteccion de flanco *)
    estadoForzado  : ARRAY[0..7] OF BOOL;  (* Valores forzados en modo mantenimiento *)
    prevEstadoSeguro : BOOL;               (* Valor anterior de estadoSeguro *)
    i              : INT;                  (* Indice de iteracion *)
    primerCiclo    : BOOL := TRUE;         (* Bandera de primer ciclo para inicializacion *)
END_VAR

(* --- Inicializacion en el primer ciclo: modo manual por defecto --- *)
IF primerCiclo THEN
    modoActivo   := 1;
    primerCiclo  := FALSE;
END_IF;

(* --- Gestion del cambio de modo --- *)
(* Solo se acepta un selector valido (0-2) cuando estadoSeguro esta activo *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        IF selector <> modoActivo THEN
            (* Al salir de mantenimiento se anulan todos los forzados *)
            IF modoActivo = 2 THEN
                FOR i := 0 TO 7 DO
                    estadoForzado[i] := FALSE;
                END_FOR;
            END_IF;
            modoActivo := selector;
        END_IF;
    END_IF;
    (* Valores fuera de rango se ignoran: modoActivo no cambia *)
END_IF;

(* --- Mantenimiento: si estadoSeguro se desactiva, apagar todos los actuadores forzados --- *)
IF modoActivo = 2 THEN
    IF NOT estadoSeguro AND prevEstadoSeguro THEN
        (* Flanco descendente de estadoSeguro durante mantenimiento *)
        FOR i := 0 TO 7 DO
            estadoForzado[i] := FALSE;
        END_FOR;
    END_IF;

    (* Aplicar forzado en flanco ascendente de confirmarForzado, solo si estadoSeguro activo *)
    IF confirmarForzado AND NOT prevConfirmar THEN
        IF estadoSeguro THEN
            IF idxForzado >= 0 AND idxForzado <= 7 THEN
                estadoForzado[idxForzado] := valorForzado;
            END_IF;
            (* idxForzado fuera de rango se ignora *)
        END_IF;
    END_IF;
END_IF;

(* --- Actualizacion de salidas segun modo vigente --- *)
CASE modoActivo OF
    0: (* Automatico: cada actuador sigue a cmdAuto *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    1: (* Manual: cada actuador sigue a cmdManual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    2: (* Mantenimiento: actuadores reflejan los forzados (apagados si no se han forzado) *)
        FOR i := 0 TO 7 DO
            actuador[i] := estadoForzado[i];
        END_FOR;
END_CASE;

(* --- Guardar valores previos para proxima ejecucion --- *)
prevConfirmar    := confirmarForzado;
prevEstadoSeguro := estadoSeguro;

END_FUNCTION_BLOCK
```