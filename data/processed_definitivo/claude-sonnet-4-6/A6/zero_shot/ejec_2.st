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
    confirmarForzado_ant: BOOL := FALSE;    (* Valor anterior de confirmarForzado *)
    estadoSeguro_ant    : BOOL := FALSE;    (* Valor anterior de estadoSeguro *)
    i                   : INT;              (* Índice de bucle *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 1. GESTIÓN DE CAMBIO DE MODO                                                *)
(*    Solo se acepta un nuevo modo si estadoSeguro está activo                 *)
(*    y el valor de selector es válido (0..2).                                 *)
(* ─────────────────────────────────────────────────────────────────────────── *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        (* Detectar salida del modo mantenimiento para anular forzados *)
        IF modoInterno = 2 AND selector <> 2 THEN
            (* Apagar todos los actuadores al salir de mantenimiento *)
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;

        modoInterno := selector;    (* Aplicar el nuevo modo *)
    END_IF;
END_IF;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 2. CONTROL DE ACTUADORES SEGÚN MODO VIGENTE                                 *)
(* ─────────────────────────────────────────────────────────────────────────── *)
CASE modoInterno OF

    (* ── Modo 0: AUTOMÁTICO ─────────────────────────────────────────────── *)
    0:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;

    (* ── Modo 1: MANUAL ─────────────────────────────────────────────────── *)
    1:
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;

    (* ── Modo 2: MANTENIMIENTO ──────────────────────────────────────────── *)
    2:
        (* 2a. Si estadoSeguro se desactiva, anular todos los forzados *)
        IF NOT estadoSeguro AND estadoSeguro_ant THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
            END_FOR;
        END_IF;

        (* 2b. Aplicar forzado individual en flanco ascendente de confirmarForzado,
               solo si estadoSeguro está activo e idxForzado es válido *)
        IF confirmarForzado AND NOT confirmarForzado_ant THEN
            IF estadoSeguro THEN
                IF idxForzado >= 0 AND idxForzado <= 7 THEN
                    actuador[idxForzado] := valorForzado;
                END_IF;
                (* idxForzado fuera de rango: se ignora silenciosamente *)
            END_IF;
        END_IF;

    (* ── Valor de selector no contemplado: no debería ocurrir ───────────── *)
    ELSE
        modoInterno := 1;   (* Fallback seguro: Manual *)

END_CASE;

(* ─────────────────────────────────────────────────────────────────────────── *)
(* 3. ACTUALIZAR SALIDA Y VARIABLES DE MEMORIA                                 *)
(* ─────────────────────────────────────────────────────────────────────────── *)
modoActivo          := modoInterno;
confirmarForzado_ant := confirmarForzado;
estadoSeguro_ant    := estadoSeguro;

END_FUNCTION_BLOCK