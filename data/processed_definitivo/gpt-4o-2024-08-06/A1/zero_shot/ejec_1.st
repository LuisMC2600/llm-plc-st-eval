FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;      // Setpoint
    PV : REAL;      // Process Variable
    Kp : REAL;      // Proportional Gain
    Ti : REAL;      // Integral Time (seconds)
    Td : REAL;      // Derivative Time (seconds)
    ciclo : TIME;   // Sampling period
END_VAR

VAR_OUTPUT
    CV : REAL;      // Control Variable (output)
END_VAR

VAR
    e : REAL;               // Error
    e_prev : REAL;          // Previous error
    integral : REAL;        // Integral term
    derivative : REAL;      // Derivative term
    dt : REAL;              // Sampling period in seconds
    CV_unsat : REAL;        // Unsaturated control variable
END_VAR

VAR CONSTANT
    CV_MIN : REAL := 0.0;   // Minimum CV
    CV_MAX : REAL := 100.0; // Maximum CV
END_VAR

// Convert TIME to seconds
dt := TO_REAL(ciclo) / 1000.0;

// Calculate error
e := SP - PV;

// Proportional term
CV_unsat := Kp * e;

// Integral term
IF Ti > 0.0 THEN
    integral := integral + (e * dt / Ti);
    
    // Anti-windup: Clamping
    IF CV_unsat >= CV_MAX THEN
        IF e > 0.0 THEN
            integral := integral - (e * dt / Ti); // Prevent positive windup
        END_IF
    ELSIF CV_unsat <= CV_MIN THEN
        IF e < 0.0 THEN
            integral := integral - (e * dt / Ti); // Prevent negative windup
        END_IF
    END_IF
END_IF

// Add integral term
CV_unsat := CV_unsat + Kp * integral;

// Derivative term
derivative := Td * (e - e_prev) / dt;
CV_unsat := CV_unsat + Kp * derivative;

// Update previous error
e_prev := e;

// Saturate CV
IF CV_unsat > CV_MAX THEN
    CV := CV_MAX;
ELSIF CV_unsat < CV_MIN THEN
    CV := CV_MIN;
ELSE
    CV := CV_unsat;
END_IF

END_FUNCTION_BLOCK