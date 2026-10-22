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
    CV : REAL; (* Variable de control (0.0 a 100.0) *)
END_VAR
VAR
    e : REAL; (* Error actual *)
    e_prev : REAL; (* Error del ciclo anterior *)
    integral_acc : REAL; (* Acumulador de la integral del error *)
    dt_sec : REAL; (* Tiempo de ciclo en segundos *)
    deriv : REAL; (* Derivada del error *)
    I_term : REAL; (* Termino integral *)
    D_term : REAL; (* Termino derivativo *)
    CV_temp : REAL; (* Variable de control sin limitar *)
END_VAR

(* Conversion del tiempo de ciclo a segundos *)
dt_sec := TIME_TO_REAL(ciclo) / 1000.0;

(* Calculo del error *)
e := SP - PV;

(* Accion Integral con Anti-windup por clamping *)
IF Ti > 0.0 THEN
    (* Evita acumular error positivo si CV esta al 100%, o negativo si CV esta al 0% *)
    IF NOT ((CV >= 100.0 AND e > 0.0) OR (CV <= 0.0 AND e < 0.0)) THEN
        integral_acc := integral_acc + (e * dt_sec);
    END_IF;
    I_term := integral_acc / Ti;
ELSE
    integral_acc := 0.0;
    I_term := 0.0;
END_IF;

(* Accion Derivativa *)
IF dt_sec > 0.0 THEN
    deriv := (e - e_prev) / dt_sec;
ELSE
    deriv := 0.0;
END_IF;
D_term := Td * deriv;

(* Ecuacion PID estandar *)
CV_temp := Kp * (e + I_term + D_term);

(* Limitacion de la salida (0.0 a 100.0) *)
IF CV_temp > 100.0 THEN
    CV := 100.0;
ELSIF CV_temp < 0.0 THEN
    CV := 0.0;
ELSE
    CV := CV_temp;
END_IF;

(* Actualizacion del error para el calculo derivativo del proximo ciclo *)
e_prev := e;

END_FUNCTION_BLOCK