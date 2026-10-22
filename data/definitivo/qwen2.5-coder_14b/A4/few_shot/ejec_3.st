FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; (* Consigna de velocidad *)
    paroRapido : BOOL; (* Paro rápido activo *)
    ciclo : TIME; (* Ciclo de ejecución *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Consigna de velocidad variable *)
END_VAR
VAR
    error : REAL; (* Error entre SPvel y CVvel *)
    deltaCV : REAL; (* Cambio en CVvel *)
    rampaSubida : REAL := 10.0; (* Pendiente de subida en puntos porcentuales por segundo *)
    rampaBajada : REAL := 20.0; (* Pendiente de bajada en puntos porcentuales por segundo *)
    rampaParoRapido : REAL := 40.0; (* Pendiente de paro rápido en puntos porcentuales por segundo *)
    tiempoCiclo : TIME := T#1S; (* Tiempo de ciclo en segundos *)
END_VAR

(* Calcular el tiempo de ciclo en segundos *)
tiempoCiclo := ciclo;

(* Calcular el error *)
error := SPvel - CVvel;

(* Calcular el cambio en CVvel *)
IF paroRapido THEN
    deltaCV := rampaParoRapido * tiempoCiclo;
    IF CVvel > 0.0 THEN
        CVvel := CVvel - deltaCV;
        IF CVvel < 0.0 THEN
            CVvel := 0.0;
        END_IF
    END_IF
ELSE
    IF error > 0 THEN
        deltaCV := rampaSubida * tiempoCiclo;
    ELSE
        deltaCV := rampaBajada * tiempoCiclo;
    END_IF
    CVvel := CVvel + deltaCV;
    (* Evitar sobrepaso *)
    IF CVvel > SPvel THEN
        CVvel := SPvel;
    ELSIF CVvel < SPvel THEN
        CVvel := SPvel;
    END_IF
END_IF

END_FUNCTION_BLOCK