```pascal
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel     : REAL; (* Consigna de velocidad [%] *)
    paroRapido: BOOL; (* Paro rápido activo *)
    ciclo     : TIME; (* Período de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    CVvel : REAL; (* Salida de velocidad con rampa [%] *)
END_VAR

VAR
    rSegundos   : REAL; (* Período en segundos *)
    rMaxSubida  : REAL; (* Incremento máximo por ciclo al subir *)
    rMaxBajada  : REAL; (* Decremento máximo por ciclo al bajar *)
    rMaxParada  : REAL; (* Decremento máximo por ciclo en paro rápido *)
    rError      : REAL; (* Diferencia entre SP y CV *)
END_VAR

(* ── Constantes de pendiente [puntos porcentuales / segundo] ── *)
CONST
    PENDIENTE_SUBIDA : REAL := 10.0;
    PENDIENTE_BAJADA : REAL := 20.0;
    PENDIENTE_PARO   : REAL := 40.0;
END_CONST

(* ── Conversión del período de ciclo a segundos ── *)
rSegundos := TIME_TO_REAL(ciclo) / 1000.0;

(* ── Incrementos máximos permitidos en este ciclo ── *)
rMaxSubida := PENDIENTE_SUBIDA * rSegundos;
rMaxBajada := PENDIENTE_BAJADA * rSegundos;
rMaxParada := PENDIENTE_PARO  * rSegundos;

IF paroRapido THEN
    (* ── Paro rápido: descender hacia 0.0 ignorando SPvel ── *)
    IF CVvel > 0.0 THEN
        CVvel := CVvel - rMaxParada;
        IF CVvel < 0.0 THEN
            CVvel := 0.0; (* Sin sobrepaso por debajo de 0 *)
        END_IF;
    ELSIF CVvel < 0.0 THEN
        (* Si por alguna razón CV fuera negativo, llevarlo a 0 *)
        CVvel := CVvel + rMaxParada;
        IF CVvel > 0.0 THEN
            CVvel := 0.0;
        END_IF;
    END_IF;
    (* Mientras paroRapido siga activo y CV = 0, permanece en 0 *)
ELSE
    (* ── Seguimiento normal de la consigna con rampa ── *)
    rError := SPvel - CVvel;

    IF rError > 0.0 THEN
        (* Subida: limitar el incremento a rMaxSubida *)
        CVvel := CVvel + rMaxSubida;
        IF CVvel > SPvel THEN
            CVvel := SPvel; (* Sin sobrepaso por arriba *)
        END_IF;

    ELSIF rError < 0.0 THEN
        (* Bajada: limitar el decremento a rMaxBajada *)
        CVvel := CVvel - rMaxBajada;
        IF CVvel < SPvel THEN
            CVvel := SPvel; (* Sin sobrepaso por abajo *)
        END_IF;

    (* Si rError = 0.0, CVvel ya es igual a SPvel; no se hace nada *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK
```