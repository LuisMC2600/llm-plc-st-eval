FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* Selector de modo *)
    estadoSeguro : BOOL; (* Estado de seguridad *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos automáticos para los actuadores *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos manuales para los actuadores *)
    idxForzado : INT; (* Índice del actuador a forzar *)
    valorForzado : BOOL; (* Valor a forzar en el actuador *)
    confirmarForzado : BOOL; (* Confirmación de forzado *)
END_VAR
VAR_OUTPUT
    modoActivo : INT; (* Modo activo *)
    actuador : ARRAY[0..7] OF BOOL; (* Estado de los actuadores *)
END_VAR
VAR
    modoVigente : INT := 1; (* Modo vigente inicializado a manual *)
    forzado : ARRAY[0..7] OF BOOL := [FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE]; (* Estado de forzado de los actuadores *)
END_VAR

(* Gestión de modos *)
IF estadoSeguro THEN
    CASE selector OF
        0: modoVigente := 0; (* Modo automático *)
        1: modoVigente := 1; (* Modo manual *)
        2: modoVigente := 2; (* Modo mantenimiento *)
    END_CASE;
END_IF;

(* Mantener el modo vigente si el selector está fuera de rango o estadoSeguro es falso *)
IF selector > 2 OR selector < 0 OR NOT estadoSeguro THEN
    modoVigente := modoVigente;
END_IF;

(* Aplicar el modo activo *)
modoActivo := modoVigente;

(* Gestión de actuadores según el modo *)
CASE modoActivo OF
    0: (* Modo automático *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdAuto[i];
        END_FOR;
    1: (* Modo manual *)
        FOR i := 0 TO 7 DO
            actuador[i] := cmdManual[i];
        END_FOR;
    2: (* Modo mantenimiento *)
        FOR i := 0 TO 7 DO
            actuador[i] := FALSE;
        END_FOR;
        IF confirmarForzado THEN
            IF idxForzado >= 0 AND idxForzado <= 7 THEN
                actuador[idxForzado] := valorForzado;
                forzado[idxForzado] := TRUE;
            END_IF;
        END_IF;
        IF NOT estadoSeguro THEN
            FOR i := 0 TO 7 DO
                actuador[i] := FALSE;
                forzado[i] := FALSE;
            END_FOR;
        END_IF;
END_CASE;

(* Anular forzados al salir del modo mantenimiento *)
IF modoActivo <> 2 THEN
    FOR i := 0 TO 7 DO
        forzado[i] := FALSE;
    END_FOR;
END_IF;

END_FUNCTION_BLOCK