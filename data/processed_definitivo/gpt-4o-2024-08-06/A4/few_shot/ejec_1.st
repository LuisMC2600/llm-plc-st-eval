FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; (* Consigna de velocidad *)
    paroRapido : BOOL; (* Activar paro rápido *)
    ciclo : TIME; (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Velocidad de consigna con rampa *)
END_VAR
VAR
    incremento : REAL; (* Incremento calculado por ciclo *)
    tiempoSegundos : REAL; (* Tiempo de ciclo en segundos *)
END_VAR

(* Convertir el tiempo de ciclo a segundos *)
tiempoSegundos := REAL_TO_REAL(TIME_TO_REAL(ciclo)) / 1000.0;

IF paroRapido THEN
    (* Paro rápido: disminuir CVvel hacia 0.0 con pendiente de 40.0 puntos porcentuales por segundo *)
    incremento := -40.0 * tiempoSegundos;
    CVvel := CVvel + incremento;
    IF CVvel < 0.0 THEN
        CVvel := 0.0;
    END_IF
ELSE
    (* Ajuste normal de CVvel hacia SPvel *)
    IF SPvel > CVvel THEN
        (* Aumentar CVvel hacia SPvel con pendiente de 10.0 puntos porcentuales por segundo *)
        incremento := 10.0 * tiempoSegundos;
        CVvel := CVvel + incremento;
        IF CVvel > SPvel THEN
            CVvel := SPvel;
        END_IF
    ELSIF SPvel < CVvel THEN
        (* Disminuir CVvel hacia SPvel con pendiente de 20.0 puntos porcentuales por segundo *)
        incremento := -20.0 * tiempoSegundos;
        CVvel := CVvel + incremento;
        IF CVvel < SPvel THEN
            CVvel := SPvel;
        END_IF
    END_IF
END_IF
END_FUNCTION_BLOCK