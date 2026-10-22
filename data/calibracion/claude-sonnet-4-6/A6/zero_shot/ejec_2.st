```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector        : INT;          (* 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro    : BOOL;         (* Condición de seguridad activa *)
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
    inicializado        : BOOL;     (* Bandera de primera ejecución *)
END_VAR

(* ─────────────────────────────────────────────
   INICIALIZACIÓN EN PRIMER CICLO
   ───────────────────────────────────────────── *)
IF NOT inicializado THEN
    modoActivo          := 1;       (* Modo inicial: Manual *)
    hayPendiente        := FALSE;
    confirmarForzado_ant := FALSE;
    estadoSeguro_ant    := FALSE;
    FOR i := 0 TO 7 DO
        actuador[i] := FALSE;
    END_FOR;
    inicializado := TRUE;
END_IF;

(* ─────────────────────────────────────────────
   GESTIÓN DE CAMBIO DE MODO
   ───────────────────────────────────────────── *)

(* Solo se consideran valores de selector válidos (0..2) *)
IF selector >= 0 AND selector <= 2 THEN

    IF estadoSeguro THEN
        (* Estado seguro activo: aplicar cambio inmediatamente si es diferente *)
        IF selector <> modoActivo THEN
            (* Al salir de mantenimiento, apagar todos los actuadores *)
            IF modoActivo = 2 THEN
                FOR i := 0 TO 7 DO
                    actuador[i] := FALSE;
                END_FOR;
            END_IF;
            modoActivo   := selector;
        END_IF;
        (* Limpiar pendiente si lo había *)
        hayPendiente := FALSE;

    ELSE
        (* Estado seguro inactivo: registrar cambio como pendiente *)
        IF selector <> modoActivo THEN
            modoPendiente := selector;
            hayPendiente  := TRUE;
        ELSE
            (* El selector volvió al modo vigente; cancelar pendiente *)
            hayPendiente := FALSE;
        END_IF;
    END_IF;

ELSE
    (* Selector fuera de rango: ignorar, cancelar pendiente si lo había *)
    hayPendiente := FALSE;
END_IF;

(* Flanco ascendente de estadoSeguro: aplicar cambio pendiente si existe *)
IF estadoSeguro AND NOT estadoSeguro_ant THEN
    IF hayPendiente THEN
        (* Al salir de mantenimiento, apagar todos los actuadores *)
        IF modoActivo = 2 THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;
        modoActivo   := modoPendiente;
        hayPendiente := FALSE;
    END_IF;
END_IF;

(* ─────────────────────────────────────────────
   LÓGICA DE ACTUADORES SEGÚN MODO VIGENTE
   ───────────────────────────────────────────── *)

CASE modoActivo OF

    0: (* ── MODO AUTOMÁTICO ── *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    1: (* ── MODO MANUAL ── *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    2: (* ── MODO MANTENIMIENTO ── *)

        (* Si estadoSeguro se desactiva, anular todos los forzados *)
        IF NOT estadoSeguro AND estadoSeguro_ant THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;

        (* Aplicar forzado en flanco ascendente de confirmarForzado,
           solo si estadoSeguro está activo e idxForzado es válido *)
        IF confirmarForzado AND NOT confirmarForzado_ant THEN
            IF estadoSeguro THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
                (* idxForzado fuera de rango: se ignora silenciosamente *)
            END_IF;
        END_IF;

END_CASE;

(* ─────────────────────────────────────────────
   ACTUALIZACIÓN DE VALORES ANTERIORES
   ───────────────────────────────────────────── *)
confirmarForzado_ant := confirmarForzado;
estadoSeguro_ant     := estadoSeguro;

END_FUNCTION_BLOCK
```