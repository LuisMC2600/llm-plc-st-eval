FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; (* Consigna de velocidad *)
    paroRapido : BOOL; (* Activa el paro rapido *)
    ciclo : TIME; (* Periodo de ejecucion del bloque *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Velocidad de salida con rampa *)
END_VAR
VAR
    deltaT : REAL; (* Tiempo de ciclo en segundos *)
    objetivo : REAL; (* Valor objetivo a alcanzar *)
    paso : REAL; (* Magnitud del cambio permitido en el ciclo *)
END_VAR

(* Calculo del tiempo de ciclo en segundos *)
deltaT := TIME_TO_REAL(ciclo) / 1000.0;

(* Determinar el valor objetivo y el paso maximo segun el estado *)
IF paroRapido THEN
    objetivo := 0.0;
    paso := 40.0 * deltaT; (* Pendiente de paro rapido *)
ELSE
    objetivo := SPvel;
    IF objetivo > CVvel THEN
        paso := 10.0 * deltaT; (* Pendiente de subida *)
    ELSE
        paso := 20.0 * deltaT; (* Pendiente de bajada *)
    END_IF;
END_IF;

(* Aplicar la rampa hacia el objetivo sin sobrepaso *)
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