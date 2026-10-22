```st
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector       : INT;                  (* Modo deseado: 0=Auto, 1=Manual, 2=Mant. *)
    estadoSeguro   : BOOL;                 (* Permiso para cambiar modo y forzar *)
    cmdAuto        : ARRAY[0..7] OF BOOL;  (* Comandos en modo automatico *)
    cmdManual      : ARRAY[0..7] OF BOOL;  (* Comandos en modo manual *)
    idxForzado     : INT;                  (* Indice del actuador a forzar *)
    valorForzado   : BOOL;                 (* Valor a aplicar al actuador forzado *)
    confirmarForzado : BOOL;               (* Flanco ascendente aplica el forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT;                      (* Modo vigente: 0=Auto, 1=Manual, 2=Mant. *)
    actuador   : ARRAY[0..7] OF BOOL;     (* Estado de los ocho actuadores *)
END_VAR
VAR
    i                  : INT;             (* Indice de iteracion *)
    prevConfirmar      : BOOL;            (* Valor anterior de confirmarForzado *)
    prevEstadoSeguro   : BOOL;            (* Valor anterior de estadoSeguro *)
    estadosForzados    : ARRAY[0..7] OF BOOL; (* Valores forzados en mantenimiento *)
    primerCiclo        : BOOL := TRUE;    (* Marca de primer ciclo para inicializacion *)
END_VAR

(* ── Inicializacion en el primer ciclo: modo manual ── *)
IF primerCiclo THEN
    modoActivo  := 1;
    primerCiclo := FALSE;
END_IF;

(* ── Gestion de cambio de modo ── *)
(* Solo se acepta un selector valido (0..2) cuando estadoSeguro esta activo *)
IF estadoSeguro AND (selector >= 0) AND (selector <= 2) THEN
    IF selector <> modoActivo THEN
        (* Al salir de mantenimiento, anular todos los forzados *)
        IF modoActivo = 2 THEN
            FOR i := 0 TO 7 DO
                estadosForzados[i] := FALSE;
            END_FOR;
        END_IF;
        modoActivo := selector;
    END_IF;
END_IF;

(* ── Logica especifica de mantenimiento ── *)
IF modoActivo = 2 THEN

    (* Si estadoSeguro se desactiva durante mantenimiento: apagar y anular forzados *)
    IF prevEstadoSeguro AND NOT estadoSeguro THEN
        FOR i := 0 TO 7 DO
            estadosForzados[i] := FALSE;
        END_FOR;
    END_IF;

    (* Detectar flanco ascendente de confirmarForzado *)
    IF confirmarForzado AND NOT prevConfirmar THEN
        (* Solo si estadoSeguro activo e indice valido *)
        IF estadoSeguro AND (idxForzado >= 0) AND (idxForzado <= 7) THEN
            estadosForzados[idxForzado] := valorForzado;
        END_IF;
    END_IF;

END_IF;

(* ── Actualizacion de salidas de actuadores ── *)
FOR i := 0 TO 7 DO
    CASE modoActivo OF
        0: (* Automatico *)
            actuador[i] := cmdAuto[i];
        1: (* Manual *)
            actuador[i] := cmdManual[i];
        2: (* Mantenimiento *)
            IF estadoSeguro THEN
                actuador[i] := estadosForzados[i];
            ELSE
                actuador[i] := FALSE; (* Sin estado seguro, todo apagado *)
            END_IF;
    ELSE
        actuador[i] := FALSE; (* Modo desconocido: seguridad *)
    END_CASE;
END_FOR;

(* ── Guardar valores previos para proximos ciclos ── *)
prevConfirmar    := confirmarForzado;
prevEstadoSeguro := estadoSeguro;

END_FUNCTION_BLOCK
```