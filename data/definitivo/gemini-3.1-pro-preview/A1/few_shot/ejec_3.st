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
    integral : REAL; (* Acumulador de la integral del error *)
    dt : REAL; (* Tiempo de ciclo en segundos *)
    P_term : REAL; (* Accion proporcional *)
    I_term : REAL; (* Accion integral *)
    D_term : REAL; (* Accion derivativa *)
    CV_unc : REAL; (* Salida calculada sin limitar *)
END_VAR

(* Conversion del tiempo de ciclo a segundos *)
dt := TIME_TO_REAL(ciclo) / 1000.0;
IF dt <= 0.0 THEN
    dt := 0.001; (* Evitar division por cero *)
END_IF;

(* Calculo del error *)
e := SP - PV;

(* Accion proporcional *)
P_term := Kp * e;

(* Accion derivativa sobre el error *)
D_term := Kp * Td * ((e - e_prev) / dt);

(* Accion integral y calculo de salida sin limitar *)
IF Ti > 0.0 THEN
    (* Se evalua con la integral tentativa para el ciclo actual *)
    I_term := Kp * ((integral + (e * dt)) / Ti);
ELSE
    I_term := 0.0;
    integral := 0.0;
END_IF;

CV_unc := P_term + I_term + D_term;

(* Anti-windup por clamping: actualizacion del acumulador integral *)
IF Ti > 0.0 THEN
    (* No acumula si esta saturado al maximo y el error es positivo, o saturado al minimo y el error es negativo *)
    IF NOT ((CV_unc >= 100.0 AND e > 0.0) OR (CV_unc <= 0.0 AND e < 0.0)) THEN
        integral := integral + (e * dt);
    END_IF;
END_IF;

(* Limitacion de la salida CV al rango 0.0 - 100.0 *)
IF CV_unc > 100.0 THEN
    CV := 100.0;
ELSIF CV_unc < 0.0 THEN
    CV := 0.0;
ELSE
    CV := CV_unc;
END_IF;

(* Memoria del error para la derivada en el proximo ciclo *)
e_prev := e;
END_FUNCTION_BLOCK