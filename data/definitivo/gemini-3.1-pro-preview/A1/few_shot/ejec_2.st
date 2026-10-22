FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL; (* Consigna *)
    PV : REAL; (* Variable de proceso *)
    Kp : REAL; (* Ganancia proporcional *)
    Ti : REAL; (* Tiempo integral en segundos *)
    Td : REAL; (* Tiempo derivativo en segundos *)
    ciclo : TIME; (* Periodo de muestreo *)
END_VAR
VAR_OUTPUT
    CV : REAL; (* Porcentaje de mando (0.0 a 100.0) *)
END_VAR
VAR
    e : REAL; (* Error actual *)
    e_prev : REAL; (* Error del ciclo anterior *)
    integral : REAL; (* Acumulador de la integral *)
    derivada : REAL; (* Tasa de cambio del error *)
    dt : REAL; (* Tiempo de ciclo en segundos *)
    CV_raw : REAL; (* Salida calculada sin limitar *)
END_VAR

(* Conversion del tiempo de ciclo a segundos *)
dt := DINT_TO_REAL(TIME_TO_DINT(ciclo)) / 1000.0;

IF dt > 0.0 THEN
    (* Calculo del error *)
    e := SP - PV;

    (* Accion integral con anti-windup por clamping *)
    IF Ti > 0.0 THEN
        (* Evitar integracion si la salida esta saturada y el error empuja en la misma direccion *)
        IF NOT ((CV >= 100.0 AND e > 0.0) OR (CV <= 0.0 AND e < 0.0)) THEN
            integral := integral + (e * dt);
        END_IF;
    ELSE
        integral := 0.0; (* Desactivar accion integral si Ti <= 0.0 *)
    END_IF;

    (* Accion derivativa sobre el error *)
    derivada := (e - e_prev) / dt;

    (* Calculo de la salida (Forma estandar del PID) *)
    IF Ti > 0.0 THEN
        CV_raw := Kp * (e + (integral / Ti) + (Td * derivada));
    ELSE
        CV_raw := Kp * (e + (Td * derivada));
    END_IF;

    (* Limitacion de la salida al rango 0.0 - 100.0 *)
    IF CV_raw > 100.0 THEN
        CV := 100.0;
    ELSIF CV_raw < 0.0 THEN
        CV := 0.0;
    ELSE
        CV := CV_raw;
    END_IF;

    (* Actualizar el error anterior para el proximo ciclo *)
    e_prev := e;
END_IF;
END_FUNCTION_BLOCK