```iecst
FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;      (* Consigna (Setpoint) *)
    PV : REAL;      (* Variable de proceso *)
    Kp : REAL;      (* Ganancia proporcional *)
    Ti : REAL;      (* Tiempo integral en segundos *)
    Td : REAL;      (* Tiempo derivativo en segundos *)
    ciclo : TIME;   (* Período de muestreo *)
END_VAR

VAR_OUTPUT
    CV : REAL;      (* Variable de control (0.0 a 100.0) *)
END_VAR

VAR
    e : REAL;       (* Error actual *)
    e_prev : REAL;  (* Error del ciclo anterior *)
    I_term : REAL;  (* Término integral acumulado *)
    P_term : REAL;  (* Término proporcional *)
    D_term : REAL;  (* Término derivativo *)
    dt : REAL;      (* Tiempo de ciclo en segundos *)
END_VAR

(* Convertir el tiempo de ciclo a segundos (REAL) *)
dt := TIME_TO_REAL(ciclo) / 1000.0;

(* Evitar ejecución si el tiempo de ciclo es inválido o cero *)
IF dt > 0.0 THEN
    
    (* Cálculo del error (Acción directa: si PV < SP, e > 0 y CV aumenta) *)
    e := SP - PV;

    (* 1. Término Proporcional *)
    P_term := Kp * e;

    (* 2. Término Integral con Anti-windup (Clamping) *)
    IF Ti > 0.0 THEN
        (* Evaluar saturación de la salida en el ciclo anterior y el signo del error *)
        IF NOT ((CV >= 100.0 AND e > 0.0) OR (CV <= 0.0 AND e < 0.0)) THEN
            I_term := I_term + (Kp * e * dt) / Ti;
        END_IF;
    ELSE
        (* Desactivar acción integral si Ti <= 0.0 *)
        I_term := 0.0; 
    END_IF;

    (* 3. Término Derivativo (calculado sobre el error) *)
    D_term := Kp * Td * (e - e_prev) / dt;

    (* Actualizar el error para el cálculo derivativo del próximo ciclo *)
    e_prev := e;

    (* Cálculo de la salida total *)
    CV := P_term + I_term + D_term;

    (* Limitación de la salida (Saturación 0.0 a 100.0) *)
    IF CV > 100.0 THEN
        CV := 100.0;
    ELSIF CV < 0.0 THEN
        CV := 0.0;
    END_IF;

END_IF;
END_FUNCTION_BLOCK
```