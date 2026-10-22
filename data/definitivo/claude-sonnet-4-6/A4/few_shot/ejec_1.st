```st
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel      : REAL; (* Consigna de velocidad [%] *)
    paroRapido : BOOL; (* Paro rapido activo *)
    ciclo      : TIME; (* Periodo de ejecucion del bloque *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Salida de velocidad con rampa [%] *)
END_VAR
VAR
    rampaSube  : REAL := 10.0; (* Pendiente maxima de subida [% / s] *)
    rampaBAja  : REAL := 20.0; (* Pendiente maxima de bajada [% / s] *)
    rampaParo  : REAL := 40.0; (* Pendiente de paro rapido [% / s] *)
    dtSeg      : REAL;         (* Periodo de ciclo convertido a segundos *)
    maxDelta   : REAL;         (* Incremento maximo permitido en este ciclo *)
    error      : REAL;         (* Diferencia entre objetivo y CVvel *)
END_VAR

(* Convertir el periodo de ciclo de TIME a segundos *)
dtSeg := TIME_TO_REAL(ciclo) / 1000.0;

IF paroRapido THEN
    (* --- Paro rapido: descender hacia 0.0 con pendiente rampaParo --- *)
    IF CVvel > 0.0 THEN
        maxDelta := rampaParo * dtSeg;
        CVvel := CVvel - maxDelta;
        (* Evitar sobrepaso por debajo de 0.0 *)
        IF CVvel < 0.0 THEN
            CVvel := 0.0;
        END_IF;
    ELSE
        (* Mantener en 0.0 mientras paroRapido siga activo *)
        CVvel := 0.0;
    END_IF;
ELSE
    (* --- Seguimiento normal de SPvel con rampa de subida / bajada --- *)
    error := SPvel - CVvel;

    IF error > 0.0 THEN
        (* Subida: limitar incremento a rampaSube * dt *)
        maxDelta := rampaSube * dtSeg;
        IF error <= maxDelta THEN
            CVvel := SPvel; (* Alcanza el objetivo sin sobrepaso *)
        ELSE
            CVvel := CVvel + maxDelta;
        END_IF;

    ELSIF error < 0.0 THEN
        (* Bajada: limitar decremento a rampaBAja * dt *)
        maxDelta := rampaBAja * dtSeg;
        IF (-error) <= maxDelta THEN
            CVvel := SPvel; (* Alcanza el objetivo sin sobrepaso *)
        ELSE
            CVvel := CVvel - maxDelta;
        END_IF;

    (* Si error = 0.0 no se hace nada, CVvel ya esta en SPvel *)
    END_IF;
END_IF;
END_FUNCTION_BLOCK
```