FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector       : INT;                  (* Selector de modo: 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro   : BOOL;                 (* Permiso para cambiar modo y mantener forzados *)
    cmdAuto        : ARRAY[0..7] OF BOOL;  (* Comandos en modo automatico *)
    cmdManual      : ARRAY[0..7] OF BOOL;  (* Comandos en modo manual *)
    idxForzado     : INT;                  (* Indice del actuador a forzar (0..7) *)
    valorForzado   : BOOL;                 (* Valor a aplicar al actuador forzado *)
    confirmarForzado : BOOL;               (* Flanco ascendente aplica el forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT;                      (* Modo vigente: 0=Auto, 1=Manual, 2=Mantenimiento *)
    actuador   : ARRAY[0..7] OF BOOL;      (* Estado de los ocho actuadores *)
END_VAR
VAR
    modoInterno        : INT := 1;         (* Modo interno; arranca en manual *)
    estadoSeguroPrev   : BOOL;             (* Valor anterior de estadoSeguro *)
    confirmarForzadoPrev : BOOL;           (* Valor anterior de confirmarForzado para deteccion de flanco *)
    estadoForzado      : ARRAY[0..7] OF BOOL; (* Valores forzados en mantenimiento *)
    i                  : INT;             (* Indice de iteracion *)
    primeraEjecucion   : BOOL := TRUE;    (* Bandera de primera ejecucion *)
END_VAR

(* --- Inicializacion en primera ejecucion --- *)
IF primeraEjecucion THEN
    modoInterno      := 1; (* Manual por defecto *)
    primeraEjecucion := FALSE;
END_IF;

(* --- Gestion de cambio de modo --- *)
(* Solo se acepta un nuevo modo si estadoSeguro esta activo y el valor es valido (0..2) *)
IF estadoSeguro AND (selector >= 0) AND (selector <= 2) AND (selector <> modoInterno) THEN
    (* Al salir de mantenimiento, anular todos los forzados *)
    IF modoInterno = 2 THEN
        FOR i := 0 TO 7 DO
            estadoForzado[i] := FALSE;
        END_FOR;
    END_IF;
    modoInterno := selector;
END_IF;

(* --- Deteccion de flanco descendente en estadoSeguro durante mantenimiento --- *)
(* Si estadoSeguro se desactiva en modo mantenimiento, apagar todos los actuadores forzados *)
IF (NOT estadoSeguro) AND estadoSeguroPrev AND (modoInterno = 2) THEN
    FOR i := 0 TO 7 DO
        estadoForzado[i] := FALSE;
    END_FOR;
END_IF;
estadoSeguroPrev := estadoSeguro;

(* --- Logica segun modo activo --- *)
CASE modoInterno OF

    0: (* Modo automatico: actuadores siguen cmdAuto *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    1: (* Modo manual: actuadores siguen cmdManual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    2: (* Modo mantenimiento *)
        (* Forzado individual con flanco ascendente de confirmarForzado *)
        (* Solo se procesa si estadoSeguro esta activo *)
        IF estadoSeguro AND confirmarForzado AND (NOT confirmarForzadoPrev) THEN
            IF (idxForzado >= 0) AND (idxForzado <= 7) THEN
                estadoForzado[idxForzado] := valorForzado;
            END_IF;
        END_IF;
        (* Los actuadores reflejan el estado forzado *)
        FOR i := 0 TO 7 DO
            actuador[i] := estadoForzado[i];
        END_FOR;

END_CASE;

(* --- Actualizar flanco de confirmarForzado --- *)
confirmarForzadoPrev := confirmarForzado;

(* --- Reportar modo vigente --- *)
modoActivo := modoInterno;

END_FUNCTION_BLOCK