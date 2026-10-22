```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector        : INT;          (* 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro    : BOOL;         (* Permiso para cambio de modo y forzados *)
    cmdAuto         : ARRAY[0..7] OF BOOL;   (* Comandos en modo automático *)
    cmdManual       : ARRAY[0..7] OF BOOL;   (* Comandos en modo manual *)
    idxForzado      : INT;          (* Índice del actuador a forzar (0..7) *)
    valorForzado    : BOOL;         (* Valor a aplicar al actuador forzado *)
    confirmarForzado: BOOL;         (* Flanco ascendente aplica el forzado *)
END_VAR

VAR_OUTPUT
    modoActivo  : INT;                      (* Modo vigente: 0, 1 ó 2 *)
    actuador    : ARRAY[0..7] OF BOOL;      (* Estado de los ocho actuadores *)
END_VAR

VAR
    modoInterno         : INT := 1;         (* Modo vigente interno; arranca en Manual *)
    modoPendiente       : BOOL := FALSE;    (* Hay un cambio de modo esperando estadoSeguro *)
    selectorPendiente   : INT := 1;         (* Valor del selector pendiente de aplicar *)
    confirmarForzado_ant: BOOL := FALSE;    (* Valor anterior de confirmarForzado (flanco) *)
    estadoSeguro_ant    : BOOL := FALSE;    (* Valor anterior de estadoSeguro *)
    i                   : INT;              (* Índice de bucle *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 1. GESTIÓN DE CAMBIO DE MODO                                                *)
(* ─────────────────────────────────────────────────────────────────────────── *)

(* Solo se consideran valores de selector válidos (0..2) *)
IF selector >= 0 AND selector <= 2 THEN

    IF estadoSeguro THEN
        (* Estado seguro activo: aplicar cambio inmediatamente si es distinto *)
        IF selector <> modoInterno THEN
            (* Salida de mantenimiento: anular todos los forzados *)
            IF modoInterno = 2 THEN
                FOR i := 0 TO 7 DO
                    actuador[i] := FALSE;
                END_FOR;
            END_IF;
            modoInterno := selector;
        END_IF;
        (* Limpiar pendiente si lo hubiera *)
        modoPendiente := FALSE;
    ELSE
        (* Estado seguro inactivo: registrar cambio como pendiente *)
        IF selector <> modoInterno THEN
            modoPendiente    := TRUE;
            selectorPendiente := selector;
        ELSE
            (* El selector volvió al modo vigente; cancelar pendiente *)
            modoPendiente := FALSE;
        END_IF;
    END_IF;

ELSE
    (* Selector fuera de rango: ignorar; cancelar pendiente si lo hubiera *)
    modoPendiente := FALSE;
END_IF;

(* Flanco ascendente de estadoSeguro: aplicar cambio pendiente si procede *)
IF estadoSeguro AND NOT estadoSeguro_ant THEN
    IF modoPendiente AND selectorPendiente >= 0 AND selectorPendiente <= 2 THEN
        IF selectorPendiente <> modoInterno THEN
            (* Salida de mantenimiento: anular forzados *)
            IF modoInterno = 2 THEN
                FOR i := 0 TO 7 DO
                    actuador[i] := FALSE;
                END_FOR;
            END_IF;
            modoInterno := selectorPendiente;
        END_IF;
        modoPendiente := FALSE;
    END_IF;
END_IF;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 2. LÓGICA DE ACTUADORES SEGÚN MODO                                          *)
(* ─────────────────────────────────────────────────────────────────────────── *)

CASE modoInterno OF

    (* ── Modo 0: AUTOMÁTICO ── *)
    0:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    (* ── Modo 1: MANUAL ── *)
    1:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    (* ── Modo 2: MANTENIMIENTO ── *)
    2:
        (* Si estadoSeguro se desactiva: apagar todos los actuadores *)
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        ELSE
            (* Flanco ascendente de confirmarForzado: aplicar forzado puntual *)
            IF confirmarForzado AND NOT confirmarForzado_ant THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
                (* idxForzado fuera de rango se ignora *)
            END_IF;
        END_IF;

END_CASE;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 3. ACTUALIZACIÓN DE SALIDA Y MEMORIAS DE FLANCO                             *)
(* ─────────────────────────────────────────────────────────────────────────── *)

modoActivo           := modoInterno;
confirmarForzado_ant := confirmarForzado;
estadoSeguro_ant     := estadoSeguro;

END_FUNCTION_BLOCK
```