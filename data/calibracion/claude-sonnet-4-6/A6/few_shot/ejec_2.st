```structured-text
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector       : INT;                  (* Selector de modo: 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro   : BOOL;                 (* Permiso para cambio de modo y forzados *)
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
    prevSeguro     : BOOL;                 (* Valor anterior de estadoSeguro *)
    forzados       : ARRAY[0..7] OF BOOL;  (* Valores forzados en modo mantenimiento *)
    i              : INT;                  (* Indice de iteracion *)
    flancoCon      : BOOL;                 (* Flanco ascendente de confirmarForzado *)
    flancoSeguro   : BOOL;                 (* Flanco ascendente de estadoSeguro *)
    primeraEjecucion : BOOL;              (* Bandera de inicializacion *)
END_VAR

(* ── Inicializacion en la primera ejecucion ── *)
IF NOT primeraEjecucion THEN
    modoActivo       := 1;   (* Modo inicial: manual *)
    primeraEjecucion := TRUE;
    prevConfirmar    := FALSE;
    prevSeguro       := estadoSeguro;
END_IF;

(* ── Deteccion de flancos ── *)
flancoCon    := confirmarForzado AND NOT prevConfirmar;
flancoSeguro := estadoSeguro AND NOT prevSeguro;

(* ── Gestion del cambio de modo ── *)
(* Se acepta un nuevo modo si estadoSeguro esta activo y el selector es valido (0..2) *)
IF estadoSeguro AND (selector >= 0) AND (selector <= 2) AND (selector <> modoActivo) THEN
    (* Al salir de mantenimiento se anulan todos los forzados *)
    IF modoActivo = 2 THEN
        FOR i := 0 TO 7 DO
            forzados[i] := FALSE;
        END_FOR;
    END_IF;
    modoActivo := selector;
END_IF;

(* ── Logica de modo mantenimiento ── *)
IF modoActivo = 2 THEN
    (* Si estadoSeguro se desactiva durante mantenimiento, apagar y anular forzados *)
    IF NOT estadoSeguro THEN
        FOR i := 0 TO 7 DO
            forzados[i] := FALSE;
            actuador[i] := FALSE;
        END_FOR;
    ELSE
        (* Aplicar forzado en flanco ascendente de confirmarForzado con indice valido *)
        IF flancoCon AND (idxForzado >= 0) AND (idxForzado <= 7) THEN
            forzados[idxForzado] := valorForzado;
        END_IF;
        (* Los actuadores reflejan los valores forzados *)
        FOR i := 0 TO 7 DO
            actuador[i] := forzados[i];
        END_FOR;
    END_IF;

(* ── Logica de modo automatico ── *)
ELSIF modoActivo = 0 THEN
    FOR i := 0 TO 7 DO
        actuador[i] := cmdAuto[i];
    END_FOR;

(* ── Logica de modo manual ── *)
ELSE (* modoActivo = 1 *)
    FOR i := 0 TO 7 DO
        actuador[i] := cmdManual[i];
    END_FOR;
END_IF;

(* ── Actualizacion de valores previos ── *)
prevConfirmar := confirmarForzado;
prevSeguro    := estadoSeguro;

END_FUNCTION_BLOCK
```