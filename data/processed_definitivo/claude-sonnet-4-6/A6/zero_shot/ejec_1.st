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
    modoActivo      : INT;          (* Modo vigente: 0=Auto, 1=Manual, 2=Mant. *)
    actuador        : ARRAY[0..7] OF BOOL;   (* Estado de los ocho actuadores *)
END_VAR

VAR
    modoPendiente       : INT;      (* Modo solicitado pendiente de aplicar *)
    hayPendiente        : BOOL;     (* Indica si existe un cambio pendiente *)
    confirmarForzado_ant: BOOL;     (* Valor anterior de confirmarForzado *)
    estadoSeguro_ant    : BOOL;     (* Valor anterior de estadoSeguro *)
    i                   : INT;      (* Índice auxiliar para bucles *)
    primerCiclo         : BOOL := TRUE; (* Inicialización en primer ciclo *)
END_VAR

(* ─────────────────────────────────────────────
   INICIALIZACIÓN EN PRIMER CICLO
   ───────────────────────────────────────────── *)
IF primerCiclo THEN
    modoActivo   := 1;              (* Arranque en modo Manual *)
    hayPendiente := FALSE;
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
    primerCiclo := FALSE;
END_IF;

(* ─────────────────────────────────────────────
   GESTIÓN DE CAMBIO DE MODO
   ───────────────────────────────────────────── *)

(* Solo se considera un nuevo selector si su valor es válido (0..2) *)
IF selector >= 0 AND selector <= 2 THEN

    IF estadoSeguro THEN
        (* Estado seguro activo: aplicar cambio inmediatamente si difiere *)
        IF selector <> modoActivo THEN
            (* Al salir de mantenimiento, apagar todos los actuadores *)
            IF modoActivo = 2 THEN
                FOR i := 0 TO 7 DO
                    actuador[i] := FALSE;
                END_FOR;
            END_IF;
            modoActivo   := selector;
            hayPendiente := FALSE;  (* Cambio aplicado; limpiar pendiente *)
        ELSE
            (* Selector coincide con modo actual; no hay pendiente *)
            hayPendiente := FALSE;
        END_IF;

    ELSE
        (* Estado seguro inactivo: registrar cambio como pendiente *)
        IF selector <> modoActivo THEN
            modoPendiente := selector;
            hayPendiente  := TRUE;
        END_IF;
    END_IF;

ELSE
    (* Selector fuera de rango: ignorar; limpiar pendiente si lo había
       con ese valor inválido (el pendiente previo válido se conserva) *)
    (* No se modifica hayPendiente ni modoPendiente *)
END_IF;

(* Aplicar cambio pendiente en cuanto estadoSeguro se active
   (flanco ascendente de estadoSeguro con pendiente válido) *)
IF estadoSeguro AND NOT estadoSeguro_ant AND hayPendiente THEN
    (* Verificar que el selector sigue indicando el modo pendiente *)
    IF selector = modoPendiente AND modoPendiente >= 0 AND modoPendiente <= 2 THEN
        IF modoActivo = 2 THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;
        modoActivo   := modoPendiente;
        hayPendiente := FALSE;
    ELSE
        (* El selector ya no coincide con el pendiente; descartar *)
        hayPendiente := FALSE;
    END_IF;
END_IF;

(* ─────────────────────────────────────────────
   MODO MANTENIMIENTO: ANULAR FORZADOS SI
   estadoSeguro SE DESACTIVA
   ───────────────────────────────────────────── *)
IF modoActivo = 2 AND NOT estadoSeguro THEN
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;       (* Apagar todos al perder estado seguro *)
    END_FOR;
END_IF;

(* ─────────────────────────────────────────────
   CONTROL DE ACTUADORES SEGÚN MODO VIGENTE
   ───────────────────────────────────────────── *)
CASE modoActivo OF

    0: (* AUTOMÁTICO: actuadores siguen cmdAuto *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    1: (* MANUAL: actuadores siguen cmdManual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    2: (* MANTENIMIENTO: forzado uno a uno con flanco ascendente *)
        IF estadoSeguro THEN
            (* Detectar flanco ascendente de confirmarForzado *)
            IF confirmarForzado AND NOT confirmarForzado_ant THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
                (* idxForzado fuera de rango: ignorar *)
            END_IF;
        END_IF;
        (* Si estadoSeguro está inactivo, los actuadores ya fueron
           apagados en el bloque anterior; no se hace nada más aquí *)

END_CASE;

(* ─────────────────────────────────────────────
   MEMORIZAR VALORES ANTERIORES PARA FLANCOS
   ───────────────────────────────────────────── *)
confirmarForzado_ant := confirmarForzado;
estadoSeguro_ant     := estadoSeguro;

END_FUNCTION_BLOCK