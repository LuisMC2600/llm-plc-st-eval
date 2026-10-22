```pascal
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
    CV : REAL; (* Salida de mando en % [0.0 .. 100.0] *)
END_VAR
VAR
    eActual  : REAL; (* Error actual: SP - PV *)
    eAnterior: REAL; (* Error del ciclo anterior para derivada *)
    integral : REAL; (* Acumulador de la integral del error *)
    derivada : REAL; (* Termino derivativo *)
    dt       : REAL; (* Periodo de muestreo en segundos *)
    CVraw    : REAL; (* Salida PID antes de saturar *)
END_VAR

(* Convertir el periodo de muestreo de TIME a segundos *)
dt := TIME_TO_REAL(ciclo) / 1000.0;

(* Calcular error actual *)
eActual := SP - PV;

(* --- Accion integral con anti-windup por clamping --- *)
(* Solo se acumula si Ti > 0 y la salida no esta saturada en el sentido del error *)
IF Ti > 0.0 THEN
    (* Saturacion alta: no acumular error positivo *)
    (* Saturacion baja: no acumular error negativo *)
    IF NOT (CV >= 100.0 AND eActual > 0.0) AND
       NOT (CV <= 0.0  AND eActual < 0.0) THEN
        integral := integral + eActual * dt;
    END_IF;
END_IF;

(* --- Accion derivativa sobre el error --- *)
IF dt > 0.0 THEN
    derivada := (eActual - eAnterior) / dt;
ELSE
    derivada := 0.0;
END_IF;

(* --- Calculo de la salida PID en forma estandar --- *)
(* CV = Kp * (e + (1/Ti)*integral + Td*derivada) *)
IF Ti > 0.0 THEN
    CVraw := Kp * (eActual + (1.0 / Ti) * integral + Td * derivada);
ELSE
    (* Sin accion integral *)
    CVraw := Kp * (eActual + Td * derivada);
END_IF;

(* --- Saturacion de la salida al rango [0.0 .. 100.0] --- *)
IF CVraw >= 100.0 THEN
    CV := 100.0;
ELSIF CVraw <= 0.0 THEN
    CV := 0.0;
ELSE
    CV := CVraw;
END_IF;

(* Guardar error actual para el proximo ciclo *)
eAnterior := eActual;

END_FUNCTION_BLOCK
```