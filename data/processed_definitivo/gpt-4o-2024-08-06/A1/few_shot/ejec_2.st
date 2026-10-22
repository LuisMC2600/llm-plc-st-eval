FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL; (* Consigna de temperatura *)
    PV : REAL; (* Variable de proceso *)
    Kp : REAL; (* Ganancia proporcional *)
    Ti : REAL; (* Tiempo integral en segundos *)
    Td : REAL; (* Tiempo derivativo en segundos *)
    ciclo : TIME; (* Periodo de muestreo *)
END_VAR
VAR_OUTPUT
    CV : REAL; (* Porcentaje de mando *)
END_VAR
VAR
    e : REAL; (* Error *)
    e_prev : REAL; (* Error previo *)
    integral : REAL; (* Componente integral *)
    derivada : REAL; (* Componente derivativa *)
    delta_t : REAL; (* Intervalo de tiempo en segundos *)
END_VAR

(* Calcular el error *)
e := SP - PV;

(* Calcular el intervalo de tiempo en segundos *)
delta_t := REAL_TO_TIME(ciclo) / 1000.0;

(* Calcular la componente integral si Ti es mayor que 0.0 *)
IF Ti > 0.0 THEN
    integral := integral + e * delta_t / Ti;
    
    (* Implementar anti-windup por clamping *)
    IF CV >= 100.0 THEN
        integral := MIN(integral, 0.0);
    ELSIF CV <= 0.0 THEN
        integral := MAX(integral, 0.0);
    END_IF
END_IF

(* Calcular la componente derivativa *)
derivada := (e - e_prev) / delta_t * Td;

(* Calcular la salida del controlador PID *)
CV := Kp * (e + integral + derivada);

(* Limitar la salida al rango 0.0 a 100.0 *)
CV := MAX(0.0, MIN(100.0, CV));

(* Actualizar el error previo *)
e_prev := e;
END_FUNCTION_BLOCK