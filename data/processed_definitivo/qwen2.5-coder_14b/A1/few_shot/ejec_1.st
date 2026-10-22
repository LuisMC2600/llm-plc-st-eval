FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL; (* Consigna *)
    PV : REAL; (* Variable de proceso *)
    Kp : REAL; (* Ganancia proporcional *)
    Ti : REAL; (* Tiempo integral en segundos *)
    Td : REAL; (* Tiempo derivativo en segundos *)
    ciclo : TIME; (* Ciclo de muestreo *)
END_VAR
VAR_OUTPUT
    CV : REAL; (* Salida del controlador PID *)
END_VAR
VAR
    e : REAL; (* Error *)
    e_prev : REAL; (* Error previo *)
    integral : REAL; (* Integral del error *)
    derivativa : REAL; (* Derivada del error *)
    dt : TIME; (* Intervalo de tiempo entre ejecuciones *)
END_VAR

(* Calculo del error *)
e := SP - PV;

(* Calculo de la derivativa *)
dt := ciclo;
derivativa := (e - e_prev) / REAL_TO_TIME(dt);

(* Calculo de la integral *)
IF Ti > 0.0 THEN
    integral := integral + (e * REAL_TO_TIME(dt)) / Ti;
ELSE
    integral := 0.0; (* Desactiva la acción integral *)
END_IF;

(* Anti-windup por clamping *)
IF CV >= 100.0 THEN
    IF e > 0.0 THEN
        integral := integral - e * REAL_TO_TIME(dt) / Ti; (* No acumula error positivo *)
    END_IF;
ELSIF CV <= 0.0 THEN
    IF e < 0.0 THEN
        integral := integral - e * REAL_TO_TIME(dt) / Ti; (* No acumula error negativo *)
    END_IF;
END_IF;

(* Calculo de la salida CV *)
CV := Kp * (e + integral + Td * derivativa);

(* Limita la salida CV al rango 0.0 a 100.0 *)
IF CV > 100.0 THEN
    CV := 100.0;
ELSIF CV < 0.0 THEN
    CV := 0.0;
END_IF;

(* Actualiza el error previo *)
e_prev := e;
END_FUNCTION_BLOCK