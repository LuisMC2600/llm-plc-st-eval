```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector        : INT;          (* 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro    : BOOL;         (* Permiso para cambio de modo y forzados *)
    cmdAuto         : ARRAY[0..7] OF BOOL;   (* Comandos en modo automático *)
    cmdManual       : ARRAY[0..7] OF BOOL;   (* Comandos en modo manual *)
    idxForzado      : INT;          (* Índice del actuador a forzar (0-7) *)
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
    selectorPendiente   : INT := 0;         (* Valor del selector pendiente de aplicar *)
    confirmarForzado_ant: BOOL := FALSE;    (* Valor anterior de confirmarForzado (flanco) *)
    estadoSeguro_ant    : BOOL := FALSE;    (* Valor anterior de estadoSeguro *)
    i                   : INT;              (* Índice de bucle *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 1. GESTIÓN DE CAMBIO DE MODO                                                *)
(* ─────────────────────────────────────────────────────────────────────────── *)

(* Solo se consideran valores de selector válidos: 0, 1 ó 2 *)
IF selector >= 0 AND selector <= 2 THEN

    IF selector <> modoInterno THEN
        (* El selector pide un modo distinto al vigente *)
        IF estadoSeguro THEN
            (* Cambio inmediato permitido *)
            modoInterno     := selector;
            modoPendiente   := FALSE;
        ELSE
            (* Guardar cambio pendiente hasta que estadoSeguro se active *)
            modoPendiente       := TRUE;
            selectorPendiente   := selector;
        END_IF;
    ELSE
        (* Selector coincide con modo vigente: cancelar cualquier pendiente *)
        modoPendiente := FALSE;
    END_IF;

ELSE
    (* Selector fuera de rango: se ignora; no se altera el pendiente *)
END_IF;

(* Aplicar cambio pendiente en cuanto estadoSeguro se active *)
IF modoPendiente AND estadoSeguro THEN
    (* Verificar que el selector sigue indicando el modo pendiente *)
    IF selector = selectorPendiente AND selector >= 0 AND selector <= 2 THEN
        modoInterno   := selectorPendiente;
        modoPendiente := FALSE;
    ELSE
        (* El selector ya no coincide con el pendiente: descartar *)
        modoPendiente := FALSE;
    END_IF;
END_IF;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 2. ACCIONES AL SALIR DEL MODO MANTENIMIENTO                                 *)
(*    Se detecta cuando modoInterno cambia desde 2 a otro valor.               *)
(*    Usamos estadoSeguro_ant para detectar también la desactivación dentro     *)
(*    del modo mantenimiento.                                                   *)
(* ─────────────────────────────────────────────────────────────────────────── *)

(* Desactivación de estadoSeguro durante mantenimiento: apagar todos *)
IF modoInterno = 2 AND estadoSeguro_ant AND NOT estadoSeguro THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 3. CONTROL DE ACTUADORES SEGÚN MODO                                         *)
(* ─────────────────────────────────────────────────────────────────────────── *)

CASE modoInterno OF

    0: (* ── AUTOMÁTICO ── *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    1: (* ── MANUAL ── *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    2: (* ── MANTENIMIENTO ── *)
        (* Los actuadores solo cambian por forzado explícito o por apagado de seguridad *)
        (* Detectar flanco ascendente de confirmarForzado *)
        IF confirmarForzado AND NOT confirmarForzado_ant THEN
            (* Solo se aplica si estadoSeguro está activo e índice válido *)
            IF estadoSeguro AND idxForzado >= 0 AND idxForzado <= 7 THEN
                actuador[idxForzado] := valorForzado;
            END_IF;
            (* Índice fuera de rango o sin estadoSeguro: se ignora *)
        END_IF;

END_CASE;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 4. ANULAR FORZADOS AL SALIR DEL MODO MANTENIMIENTO                          *)
(*    Se detecta transición modoInterno: 2 → otro valor.                       *)
(*    Como modoInterno ya tiene el nuevo valor, comparamos con el ciclo         *)
(*    anterior usando modoActivo (salida del ciclo previo).                     *)
(* ─────────────────────────────────────────────────────────────────────────── *)

IF modoActivo = 2 AND modoInterno <> 2 THEN
    (* Salida del modo mantenimiento: apagar todos los actuadores *)
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
END_IF;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 5. ACTUALIZAR SALIDAS Y VARIABLES DE MEMORIA                                *)
(* ─────────────────────────────────────────────────────────────────────────── *)

modoActivo           := modoInterno;
confirmarForzado_ant := confirmarForzado;
estadoSeguro_ant     := estadoSeguro;

END_FUNCTION_BLOCK
```