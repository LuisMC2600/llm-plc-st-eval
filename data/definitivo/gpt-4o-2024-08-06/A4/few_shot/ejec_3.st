```pascal
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; (* Consigna de velocidad *)
    paroRapido : BOOL; (* Señal de paro rápido *)
    ciclo : TIME; (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Velocidad de consigna con rampa *)
END_VAR
VAR
    deltaTiempo : REAL; (* Tiempo de ciclo en segundos *)
    incremento : REAL; (* Incremento de velocidad por ciclo *)
END_VAR

(* Convertir el tiempo de ciclo a segundos *)
deltaTiempo := REAL_TO_REAL(TIME_TO_REAL(ciclo)) / 1000.0;

IF paroRapido THEN
    (* Paro rápido: descender a 0.0 con pendiente de 40.0 %/s *)
    incremento := -40.0 * deltaTiempo;
    CVvel := CVvel + incremento;
    IF CVvel < 0.0 THEN
        CVvel := 0.0;
    END_IF
ELSE
    (* Ajuste normal de velocidad con rampa *)
    IF SPvel > CVvel THEN
        (* Incremento al subir: máximo 10.0 %/s *)
        incremento := 10.0 * deltaTiempo;
        CVvel := CVvel + incremento;
        IF CVvel > SPvel THEN
            CVvel := SPvel;
        END_IF
    ELSIF SPvel < CVvel THEN
        (* Decremento al bajar: máximo 20.0 %/s *)
        incremento := -20.0 * deltaTiempo;
        CVvel := CVvel + incremento;
        IF CVvel < SPvel THEN
            CVvel := SPvel;
        END_IF
    END_IF
END_IF
END_FUNCTION_BLOCK
```