FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;       // Setpoint
    PV : REAL;       // Process Variable
    Kp : REAL;       // Proportional Gain
    Ti : REAL;       // Integral Time (seconds)
    Td : REAL;       // Derivative Time (seconds)
    ciclo : TIME;    // Sampling period
END_VAR

VAR_OUTPUT
    CV : REAL;       // Control Variable (Output)
END_VAR

VAR
    e : REAL;        // Error
    e_prev : REAL;   // Previous error
    integral : REAL; // Integral term
    derivative : REAL; // Derivative term
    dt : REAL;       // Sampling period in seconds
    CV_unsat : REAL; // Unsaturated Control Variable
END_VAR

VAR CONSTANT
    CV_MIN : REAL := 0.0;   // Minimum CV
    CV_MAX : REAL := 100.0; // Maximum CV
END_VAR

// Convert ciclo from TIME to REAL (seconds)
dt := REAL_TO_TIME(ciclo) / 1000.0;

// Calculate error
e := SP - PV;

// Calculate integral term with anti-windup
IF Ti > 0.0 THEN
    integral := integral + e * dt;
    // Anti-windup clamping
    IF CV >= CV_MAX AND e > 0.0 THEN
        integral := integral - e * dt;
    ELSIF CV <= CV_MIN AND e < 0.0 THEN
        integral := integral - e * dt;
    END_IF
ELSE
    integral := 0.0;
END_IF

// Calculate derivative term
derivative := (e - e_prev) / dt;

// Calculate unsaturated CV
CV_unsat := Kp * (e + (1.0 / Ti) * integral + Td * derivative);

// Saturate CV
IF CV_unsat > CV_MAX THEN
    CV := CV_MAX;
ELSIF CV_unsat < CV_MIN THEN
    CV := CV_MIN;
ELSE
    CV := CV_unsat;
END_IF

// Update previous error
e_prev := e;

END_FUNCTION_BLOCK