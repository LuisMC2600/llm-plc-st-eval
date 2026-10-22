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
    dt : TIME; (* Tiempo transcurrido desde la última iteración *)
    dt_sec : REAL; (* Tiempo transcurrido en segundos *)
    rampaSubida : REAL := 10.0; (* Pendiente de subida en puntos porcentuales por segundo *)
    rampaBajada : REAL := 20.0; (* Pendiente de bajada en puntos porcentuales por segundo *)
    rampaParoRapido : REAL := 40.0; (* Pendiente de paro rápido en puntos porcentuales por segundo *)
    lastTime : TIME; (* Tiempo de la última iteración *)
END_VAR

(* Calcula el tiempo transcurrido desde la última iteración *)
dt := ciclo;
dt_sec := dt / T#1S;

(* Actualiza CVvel según las condiciones *)
IF paroRapido THEN
    (* Paro rápido activo *)
    CVvel := CVvel - rampaParoRapido * dt_sec;
    IF CVvel < 0.0 THEN
        CVvel := 0.0;
    END_IF;
ELSE
    (* Paro rápido inactivo *)
    error := SPvel - CVvel;
    IF error > 0 THEN
        (* Subida *)
        CVvel := CVvel + rampaSubida * dt_sec;
        IF CVvel > SPvel THEN
            CVvel := SPvel;
        END_IF;
    ELSE
        (* Bajada *)
        CVvel := CVvel - rampaBajada * dt_sec;
        IF CVvel < SPvel THEN
            CVvel := SPvel;
        END_IF;
    END_IF;
END_IF;

(* Actualiza el tiempo de la última iteración *)
lastTime := lastTime + ciclo;
END_FUNCTION_BLOCK