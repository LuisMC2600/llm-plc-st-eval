FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP    : REAL; (* Consigna (setpoint) *)
    PV    : REAL; (* Variable de proceso *)
    Kp    : REAL; (* Ganancia proporcional *)
    Ti    : REAL; (* Tiempo integral en segundos (<=0 desactiva integral) *)
    Td    : REAL; (* Tiempo derivativo en segundos *)
    ciclo : TIME; (* Periodo de muestreo *)
END_VAR
VAR_OUTPUT
    CV : REAL; (* Salida de mando 0.0..100.0 % *)
END_VAR
VAR
    eActual  : REAL; (* Error actual: SP - PV *)
    eAnterior: REAL; (* Error del ciclo anterior para derivada *)
    integral : REAL; (* Acumulador de la integral del error *)
    derivada : REAL; (* Termino derivativo *)
    dt       : REAL; (* Periodo de muestreo en segundos *)
    CVraw    : REAL; (* Salida sin saturar *)
END_VAR

(* Convertir el periodo de muestreo de TIME a segundos *)
dt := TIME_TO_REAL(ciclo) / 1000.0;

(* Calcular error actual *)
eActual := SP - PV;

(* --- Termino integral con anti-windup por clamping --- *)
IF Ti > 0.0 THEN
    (* Acumular solo si la salida no esta saturada en el sentido del error *)
    IF NOT ((CV >= 100.0 AND eActual > 0.0) OR
            (CV <=   0.0 AND eActual < 0.0)) THEN
        integral := integral + eActual * dt;
    END_IF;
ELSE
    integral := 0.0; (* Accion integral desactivada *)
END_IF;

(* --- Termino derivativo sobre el error --- *)
IF dt > 0.0 THEN
    derivada := (eActual - eAnterior) / dt;
ELSE
    derivada := 0.0;
END_IF;

(* --- Ley PID estandar --- *)
CVraw := Kp * eActual;

IF Ti > 0.0 THEN
    CVraw := CVraw + Kp * (1.0 / Ti) * integral;
END_IF;

CVraw := CVraw + Kp * Td * derivada;

(* --- Saturacion de la salida 0..100 % --- *)
IF CVraw >= 100.0 THEN
    CV := 100.0;
ELSIF CVraw <= 0.0 THEN
    CV := 0.0;
ELSE
    CV := CVraw;
END_IF;

(* Guardar error para el proximo ciclo *)
eAnterior := eActual;

END_FUNCTION_BLOCK