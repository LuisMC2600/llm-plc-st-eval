FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel     : REAL;   (* Consigna de velocidad [%] *)
    paroRapido: BOOL;   (* Paro rápido activo *)
    ciclo     : TIME;   (* Período de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    CVvel : REAL;       (* Salida de velocidad con rampa [%] *)
END_VAR

VAR
    rSegundos  : REAL;  (* Período de ciclo convertido a segundos *)
    rMaxSubida : REAL;  (* Incremento máximo permitido en un ciclo *)
    rMaxBajada : REAL;  (* Decremento máximo permitido en un ciclo *)
    rError     : REAL;  (* Diferencia entre consigna y salida actual *)
END_VAR

(* ── Constantes de pendiente [puntos porcentuales / segundo] ── *)
VAR CONSTANT
    PENDIENTE_SUBIDA    : REAL := 10.0;
    PENDIENTE_BAJADA    : REAL := 20.0;
    PENDIENTE_PARO_RAP  : REAL := 40.0;
END_VAR

(* ── Conversión del período de ciclo a segundos ── *)
rSegundos := TIME_TO_REAL(ciclo) / 1000.0;

IF paroRapido THEN
    (* ── Modo paro rápido: descender hacia 0.0 con pendiente rápida ── *)
    rMaxBajada := PENDIENTE_PARO_RAP * rSegundos;

    IF CVvel > 0.0 THEN
        CVvel := CVvel - rMaxBajada;
        (* Evitar sobrepaso por debajo de 0.0 *)
        IF CVvel < 0.0 THEN
            CVvel := 0.0;
        END_IF;
    ELSE
        (* Mantener en 0.0 mientras paroRapido siga activo *)
        CVvel := 0.0;
    END_IF;

ELSE
    (* ── Modo normal: seguir SPvel con pendientes limitadas ── *)
    rMaxSubida := PENDIENTE_SUBIDA * rSegundos;
    rMaxBajada := PENDIENTE_BAJADA * rSegundos;

    rError := SPvel - CVvel;

    IF rError > 0.0 THEN
        (* Consigna mayor que salida: subir con pendiente limitada *)
        IF rError > rMaxSubida THEN
            CVvel := CVvel + rMaxSubida;
        ELSE
            (* El paso restante es menor que el máximo: llegar exactamente *)
            CVvel := SPvel;
        END_IF;

    ELSIF rError < 0.0 THEN
        (* Consigna menor que salida: bajar con pendiente limitada *)
        IF (-rError) > rMaxBajada THEN
            CVvel := CVvel - rMaxBajada;
        ELSE
            CVvel := SPvel;
        END_IF;

    (* Si rError = 0.0, CVvel ya es igual a SPvel; no se hace nada *)
    END_IF;

END_IF;

END_FUNCTION_BLOCK