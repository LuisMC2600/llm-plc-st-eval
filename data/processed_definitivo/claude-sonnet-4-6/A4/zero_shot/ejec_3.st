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
    rPendiente  : REAL; (* Pendiente aplicada en este ciclo [puntos/%] *)
    rDelta      : REAL; (* Incremento/decremento máximo en este ciclo *)
    rSegundos   : REAL; (* Período de ciclo convertido a segundos *)
    rObjetivo   : REAL; (* Valor objetivo en este ciclo *)
END_VAR

(* ── Constantes de rampa [puntos porcentuales / segundo] ── *)
VAR CONSTANT
    C_RAMPA_SUBIDA  : REAL := 10.0;  (* Máx. subida  *)
    C_RAMPA_BAJADA  : REAL := 20.0;  (* Máx. bajada  *)
    C_RAMPA_PARO    : REAL := 40.0;  (* Paro rápido  *)
END_VAR

(* ── Conversión del período a segundos ── *)
rSegundos := TIME_TO_REAL(ciclo) / 1000.0;

IF paroRapido THEN
    (* ── Modo paro rápido: descender hacia 0.0 con rampa de 40 %/s ── *)
    rObjetivo := 0.0;

    IF CVvel > 0.0 THEN
        (* Calcular decremento máximo permitido en este ciclo *)
        rDelta := C_RAMPA_PARO * rSegundos;
        CVvel  := CVvel - rDelta;

        (* Evitar sobrepasar el objetivo (0.0) por debajo *)
        IF CVvel < 0.0 THEN
            CVvel := 0.0;
        END_IF;

    ELSIF CVvel < 0.0 THEN
        (* Si por alguna razón CVvel es negativo, subir hacia 0.0 *)
        rDelta := C_RAMPA_PARO * rSegundos;
        CVvel  := CVvel + rDelta;

        IF CVvel > 0.0 THEN
            CVvel := 0.0;
        END_IF;

    END_IF;
    (* CVvel = 0.0 exacto: no se modifica *)

ELSE
    (* ── Modo normal: seguir SPvel con rampa de subida/bajada ── *)
    rObjetivo := SPvel;

    IF CVvel < rObjetivo THEN
        (* Subida: pendiente limitada a C_RAMPA_SUBIDA *)
        rDelta := C_RAMPA_SUBIDA * rSegundos;
        CVvel  := CVvel + rDelta;

        (* Evitar sobrepasar el objetivo por arriba *)
        IF CVvel > rObjetivo THEN
            CVvel := rObjetivo;
        END_IF;

    ELSIF CVvel > rObjetivo THEN
        (* Bajada: pendiente limitada a C_RAMPA_BAJADA *)
        rDelta := C_RAMPA_BAJADA * rSegundos;
        CVvel  := CVvel - rDelta;

        (* Evitar sobrepasar el objetivo por abajo *)
        IF CVvel < rObjetivo THEN
            CVvel := rObjetivo;
        END_IF;

    END_IF;
    (* CVvel = rObjetivo exacto: no se modifica *)

END_IF;