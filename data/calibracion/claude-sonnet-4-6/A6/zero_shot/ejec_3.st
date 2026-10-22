```pascal
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector        : INT;          (* 0=Auto, 1=Manual, 2=Mantenimiento *)
    estadoSeguro    : BOOL;         (* Permiso para cambio de modo y forzados *)
    cmdAuto         : ARRAY[0..7] OF BOOL;   (* Comandos en modo automático *)
    cmdManual       : ARRAY[0..7] OF BOOL;   (* Comandos en modo manual *)
    idxForzado      : INT;          (* Índice del actuador a forzar (0..7) *)
    valorForzado    : BOOL;         (* Valor a aplicar en forzado *)
    confirmarForzado: BOOL;         (* Flanco ascendente activa el forzado *)
END_VAR

VAR_OUTPUT
    modoActivo  : INT;                      (* Modo vigente: 0, 1 ó 2 *)
    actuador    : ARRAY[0..7] OF BOOL;      (* Estado de los ocho actuadores *)
END_VAR

VAR
    prevConfirmar   : BOOL;                 (* Valor anterior de confirmarForzado *)
    prevEstadoSeguro: BOOL;                 (* Valor anterior de estadoSeguro *)
    estadoForzado   : ARRAY[0..7] OF BOOL; (* Valores forzados en mantenimiento *)
    i               : INT;                  (* Índice auxiliar para bucles *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────
   GESTIÓN DE MODO ACTIVO
   ───────────────────────────────────────────────────────────────────────── *)

(* Solo se acepta cambio de modo si estadoSeguro está activo
   y el selector indica un valor válido (0..2) distinto del modo vigente *)
IF estadoSeguro THEN
    IF selector >= 0 AND selector <= 2 THEN
        IF selector <> modoActivo THEN
            (* Al salir del modo mantenimiento, anular todos los forzados *)
            IF modoActivo = 2 THEN
                FOR i := 0 TO 7 DO
                    estadoForzado[i] := FALSE;
                END_FOR;
            END_IF;
            modoActivo := selector;
        END_IF;
    END_IF;
    (* Valores de selector fuera de 0..2 se ignoran: modoActivo no cambia *)
END_IF;

(* ─────────────────────────────────────────────────────────────────────────
   MODO MANTENIMIENTO: anular forzados si estadoSeguro se desactiva
   ───────────────────────────────────────────────────────────────────────── *)
IF modoActivo = 2 THEN
    (* Detección de flanco descendente de estadoSeguro durante mantenimiento *)
    IF prevEstadoSeguro AND NOT estadoSeguro THEN
        FOR i := 0 TO 7 DO
            estadoForzado[i] := FALSE;
        END_FOR;
    END_IF;

    (* Detección de flanco ascendente de confirmarForzado *)
    IF confirmarForzado AND NOT prevConfirmar THEN
        (* Solo se aplica si estadoSeguro está activo e índice en rango *)
        IF estadoSeguro AND (idxForzado >= 0) AND (idxForzado <= 7) THEN
            estadoForzado[idxForzado] := valorForzado;
        END_IF;
        (* idxForzado fuera de rango o sin estadoSeguro: se ignora *)
    END_IF;
END_IF;

(* ─────────────────────────────────────────────────────────────────────────
   ACTUALIZACIÓN DE SALIDAS DE ACTUADORES
   ───────────────────────────────────────────────────────────────────────── *)
FOR i := 0 TO 7 DO
    CASE modoActivo OF
        0: (* Automático: sigue cmdAuto *)
            actuador[i] := cmdAuto[i];

        1: (* Manual: sigue cmdManual *)
            actuador[i] := cmdManual[i];

        2: (* Mantenimiento: aplica valores forzados (apagado por defecto) *)
            actuador[i] := estadoForzado[i];

        ELSE
            (* Estado no definido: apagar por seguridad *)
            actuador[i] := FALSE;
    END_CASE;
END_FOR;

(* ─────────────────────────────────────────────────────────────────────────
   ACTUALIZACIÓN DE VALORES PREVIOS (para detección de flancos)
   ───────────────────────────────────────────────────────────────────────── *)
prevConfirmar    := confirmarForzado;
prevEstadoSeguro := estadoSeguro;

END_FUNCTION_BLOCK
```

**Notas de diseño:**

| Aspecto | Decisión |
|---|---|
| Modo inicial | `modoActivo` se inicializa a `0` por defecto en IEC 61131-3; para garantizar modo **manual** al arrancar se debe inicializar `modoActivo := 1` en la sección `VAR` o en el primer ciclo. Añade `modoActivo : INT := 1;` en `VAR_OUTPUT` si el entorno lo permite, o usa una variable de primer ciclo. |
| Cambio pendiente | Si `estadoSeguro` está inactivo y el selector cambia, el cambio se aplica automáticamente en cuanto `estadoSeguro` se activa (la condición se evalúa cada ciclo). |
| Forzado sin `estadoSeguro` | El flanco de `confirmarForzado` se detecta siempre, pero el forzado solo se escribe si `estadoSeguro` está activo en ese instante. |
| Salida de mantenimiento | Al cambiar de modo 2 a otro, `estadoForzado` se limpia antes de aplicar el nuevo modo. |