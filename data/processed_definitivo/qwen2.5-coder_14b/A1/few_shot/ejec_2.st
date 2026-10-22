FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL; (* Setpoint *)
    PV : REAL; (* Process Variable *)
    Kp : REAL; (* Proportional Gain *)
    Ti : REAL; (* Integral Time in seconds *)
    Td : REAL; (* Derivative Time in seconds *)
    ciclo : TIME; (* Sampling Cycle *)
END_VAR
VAR_OUTPUT
    CV : REAL; (* Control Variable, 0.0 to 100.0 *)
END_VAR
VAR
    e : REAL; (* Error *)
    ePrev : REAL; (* Previous Error *)
    integral : REAL; (* Integral of Error *)
    derivativa : REAL; (* Derivative of Error *)
    dt : TIME; (* Time Difference *)
END_VAR

(* Calculate the error *)
e := SP - PV;

(* Calculate the derivative of the error *)
dt := ciclo;
derivativa := (e - ePrev) / REAL_TO_TIME(dt);

(* Calculate the integral of the error *)
IF Ti > 0.0 THEN
    integral := integral + (e * REAL_TO_TIME(ciclo)) / Ti;
ELSE
    integral := 0.0; (* Integral action disabled *)
END_IF;

(* Anti-windup by clamping *)
IF CV >= 100.0 THEN
    IF e > 0.0 THEN
        integral := integral - e * REAL_TO_TIME(ciclo) / Ti; (* Prevent integral windup *)
    END_IF;
ELSIF CV <= 0.0 THEN
    IF e < 0.0 THEN
        integral := integral - e * REAL_TO_TIME(ciclo) / Ti; (* Prevent integral windup *)
    END_IF;
END_IF;

(* Calculate the control variable *)
CV := Kp * (e + integral + Td * derivativa);

(* Clamp the control variable to the range 0.0 to 100.0 *)
IF CV > 100.0 THEN
    CV := 100.0;
ELSIF CV < 0.0 THEN
    CV := 0.0;
END_IF;

(* Update previous error *)
ePrev := e;
END_FUNCTION_BLOCK