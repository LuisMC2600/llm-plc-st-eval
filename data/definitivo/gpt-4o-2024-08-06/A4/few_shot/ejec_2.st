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
    incremento : REAL; (* Incremento de velocidad por ciclo *)
    tiempoSegundos : REAL; (* Duración del ciclo en segundos *)
END_VAR

(* Convertir el tiempo de ciclo a segundos *)
tiempoSegundos := REAL_TO_REAL(TIME_TO_REAL(ciclo)) / 1000.0;

IF paroRapido THEN
    (* Paro rápido: disminuir CVvel a 0.0 con pendiente de 40.0 %/s *)
    incremento := -40.0 * tiempoSegundos;
    CVvel := CVvel + incremento;
    IF CVvel < 0.0 THEN
        CVvel := 0.0;
    END_IF
ELSE
    (* Rampa normal: ajustar CVvel hacia SPvel *)
    IF SPvel > CVvel THEN
        (* Incremento al subir con pendiente de 10.0 %/s *)
        incremento := 10.0 * tiempoSegundos;
        CVvel := CVvel + incremento;
        IF CVvel > SPvel THEN
            CVvel := SPvel;
        END_IF
    ELSIF SPvel < CVvel THEN
        (* Decremento al bajar con pendiente de 20.0 %/s *)
        incremento := -20.0 * tiempoSegundos;
        CVvel := CVvel + incremento;
        IF CVvel < SPvel THEN
            CVvel := SPvel;
        END_IF
    END_IF
END_IF
END_FUNCTION_BLOCK
```