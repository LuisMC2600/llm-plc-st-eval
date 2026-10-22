FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; (* Consigna de velocidad *)
    paroRapido : BOOL; (* Activa el paro rapido *)
    ciclo : TIME; (* Periodo de ejecucion *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Velocidad actual con rampa *)
END_VAR
VAR
    cicloSeg : REAL; (* Ciclo en segundos *)
    objetivo : REAL; (* Velocidad objetivo *)
    paso : REAL; (* Incremento o decremento maximo *)
END_VAR

(* Convertir tiempo de ciclo a segundos *)
cicloSeg := TIME_TO_REAL(ciclo) / 1000.0;

(* Determinar el objetivo y el paso segun las condiciones *)
IF paroRapido THEN
    objetivo := 0.0;
    paso := 40.0 * cicloSeg; (* Pendiente de paro rapido *)
ELSE
    objetivo := SPvel;
    IF CVvel < objetivo THEN
        paso := 10.0 * cicloSeg; (* Pendiente de subida *)
    ELSE
        paso := 20.0 * cicloSeg; (* Pendiente de bajada *)
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