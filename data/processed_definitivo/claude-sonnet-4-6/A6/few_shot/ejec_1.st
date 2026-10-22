FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector       : INT;                  (* Selector de modo: 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro   : BOOL;                 (* Permiso para cambiar de modo y operar mantenimiento *)
    cmdAuto        : ARRAY[0..7] OF BOOL;  (* Comandos en modo automatico *)
    cmdManual      : ARRAY[0..7] OF BOOL;  (* Comandos en modo manual *)
    idxForzado     : INT;                  (* Indice del actuador a forzar en mantenimiento *)
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
    i              : INT;                  (* Indice auxiliar para bucles *)
    primerCiclo    : BOOL := TRUE;         (* Marca de primer ciclo para inicializacion *)
END_VAR

(* --- Inicializacion en el primer ciclo de ejecucion --- *)
IF primerCiclo THEN
    modoActivo  := 1;   (* Modo inicial: manual *)
    primerCiclo := FALSE;
END_IF;

(* --- Gestion del cambio de modo --- *)
(* Solo se acepta un nuevo modo si estadoSeguro esta activo y el valor es valido (0..2) *)
IF estadoSeguro AND (selector >= 0) AND (selector <= 2) THEN
    IF selector <> modoActivo THEN
        (* Al salir del modo mantenimiento se anulan todos los forzados *)
        IF modoActivo = 2 THEN
            FOR i := 0 TO 7 DO
                estadoForzado[i] := FALSE;
            END_FOR;
        END_IF;
        modoActivo := selector;
    END_IF;
END_IF;

(* --- Logica especifica de cada modo --- *)
CASE modoActivo OF

    0: (* Modo automatico: actuadores siguen cmdAuto *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    1: (* Modo manual: actuadores siguen cmdManual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    2: (* Modo mantenimiento *)
        IF NOT estadoSeguro THEN
            (* Si se pierde el estado seguro, se anulan forzados y se apagan actuadores *)
            FOR i := 0 TO 7 DO
                estadoForzado[i] := FALSE;
                actuador[i]      := FALSE;
            END_FOR;
        ELSE
            (* Deteccion de flanco ascendente en confirmarForzado *)
            IF confirmarForzado AND NOT prevConfirmar THEN
                IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                    estadoForzado[idxForzado] := valorForzado;
                END_IF;
                (* Indices fuera de rango se ignoran *)
            END_IF;
            (* Los actuadores reflejan el estado forzado acumulado *)
            FOR i := 0 TO 7 DO
                actuador[i] := estadoForzado[i];
            END_FOR;
        END_IF;

END_CASE;

(* --- Actualizacion del valor previo de confirmarForzado --- *)
prevConfirmar := confirmarForzado;

END_FUNCTION_BLOCK