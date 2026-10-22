FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; (* Consigna de velocidad *)
    paroRapido : BOOL; (* Comando de paro rapido *)
    ciclo : TIME; (* Periodo de ejecucion del bloque *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Velocidad actual con rampa *)
END_VAR
VAR
    dt_sec : REAL; (* Tiempo de ciclo en segundos *)
    objetivo : REAL; (* Velocidad objetivo a alcanzar *)
    paso : REAL; (* Magnitud del cambio en el ciclo actual *)
END_VAR

(* Convertir el tiempo de ciclo a segundos *)
dt_sec := TIME_TO_REAL(ciclo) / 1000.0;

(* Determinar el objetivo y el paso maximo segun el estado *)
IF paroRapido THEN
    objetivo := 0.0;
    paso := 40.0 * dt_sec; (* Pendiente de paro rapido *)
ELSE
    objetivo := SPvel;
    IF CVvel < objetivo THEN
        paso := 10.0 * dt_sec; (* Pendiente de subida *)
    ELSE
        paso := 20.0 * dt_sec; (* Pendiente de bajada *)
    END_IF;
END_IF;

(* Aproximar la salida al objetivo evitando el sobrepaso *)
IF CVvel < objetivo THEN
    CVvel := CVvel + paso;
    IF CVvel > objetivo THEN
        CVvel := objetivo;
    END_IF;
ELSIF CVvel > objetivo THEN
    CVvel := CVvel - paso;
    IF CVvel < objetivo THEN
        CVvel := objetivo;
    END_IF;
END_IF;
END_FUNCTION_BLOCK