FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector       : INT;                  (* Selector de modo: 0=Auto, 1=Manual, 2=Mant. *)
    estadoSeguro   : BOOL;                 (* Permiso para cambio de modo y forzados *)
    cmdAuto        : ARRAY[0..7] OF BOOL;  (* Comandos en modo automatico *)
    cmdManual      : ARRAY[0..7] OF BOOL;  (* Comandos en modo manual *)
    idxForzado     : INT;                  (* Indice del actuador a forzar (0..7) *)
    valorForzado   : BOOL;                 (* Valor a aplicar al actuador forzado *)
    confirmarForzado : BOOL;               (* Flanco ascendente aplica el forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT;                      (* Modo vigente: 0=Auto, 1=Manual, 2=Mant. *)
    actuador   : ARRAY[0..7] OF BOOL;     (* Estado de los ocho actuadores *)
END_VAR
VAR
    i                  : INT;             (* Indice de bucle *)
    estadosForzados    : ARRAY[0..7] OF BOOL; (* Valores forzados en mantenimiento *)
    confirmarForzado_prev : BOOL;         (* Valor anterior de confirmarForzado *)
    flanco_confirmar   : BOOL;            (* Flanco ascendente detectado *)
    primerCiclo        : BOOL := TRUE;    (* Bandera de primer ciclo para inicializacion *)
    estadoSeguro_prev  : BOOL;            (* Valor anterior de estadoSeguro *)
END_VAR

(* --- Inicializacion en el primer ciclo: modo manual por defecto --- *)
IF primerCiclo THEN
    modoActivo        := 1;
    primerCiclo       := FALSE;
    confirmarForzado_prev := confirmarForzado;
    estadoSeguro_prev := estadoSeguro;
    FOR i := 0 TO 7 DO
        estadosForzados[i] := FALSE;
        actuador[i]        := FALSE;
    END_FOR;
END_IF;

(* --- Gestion del cambio de modo --- *)
(* Solo se acepta un selector valido (0..2) y con estadoSeguro activo *)
IF estadoSeguro AND (selector >= 0) AND (selector <= 2) THEN
    IF selector <> modoActivo THEN
        (* Al salir de mantenimiento, anular todos los forzados *)
        IF modoActivo = 2 THEN
            FOR i := 0 TO 7 DO
                estadosForzados[i] := FALSE;
            END_FOR;
        END_IF;
        modoActivo := selector;
        (* Al entrar en mantenimiento, apagar todos los actuadores *)
        IF modoActivo = 2 THEN
            FOR i := 0 TO 7 DO
                actuador[i]        := FALSE;
                estadosForzados[i] := FALSE;
            END_FOR;
        END_IF;
    END_IF;
END_IF;

(* --- Logica especifica de mantenimiento --- *)
IF modoActivo = 2 THEN
    (* Si estadoSeguro se desactiva durante mantenimiento: anular forzados y apagar *)
    IF (NOT estadoSeguro) AND estadoSeguro_prev THEN
        FOR i := 0 TO 7 DO
            estadosForzados[i] := FALSE;
            actuador[i]        := FALSE;
        END_FOR;
    END_IF;

    (* Detectar flanco ascendente de confirmarForzado *)
    flanco_confirmar := confirmarForzado AND (NOT confirmarForzado_prev);

    (* Aplicar forzado solo si estadoSeguro activo, flanco detectado e indice valido *)
    IF estadoSeguro AND flanco_confirmar
       AND (idxForzado >= 0) AND (idxForzado <= 7) THEN
        estadosForzados[idxForzado] := valorForzado;
    END_IF;

    (* Los actuadores reflejan los valores forzados *)
    FOR i := 0 TO 7 DO
        actuador[i] := estadosForzados[i];
    END_FOR;

(* --- Modo automatico --- *)
ELSIF modoActivo = 0 THEN
    FOR i := 0 TO 7 DO
        actuador[i] := cmdAuto[i];
    END_FOR;

(* --- Modo manual --- *)
ELSIF modoActivo = 1 THEN
    FOR i := 0 TO 7 DO
        actuador[i] := cmdManual[i];
    END_FOR;
END_IF;

(* --- Actualizar valores previos para el proximo ciclo --- *)
confirmarForzado_prev := confirmarForzado;
estadoSeguro_prev     := estadoSeguro;

END_FUNCTION_BLOCK