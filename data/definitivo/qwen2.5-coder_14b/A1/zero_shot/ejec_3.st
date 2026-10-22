```iec
FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;  // Setpoint
    PV : REAL;  // Process Variable
    Kp : REAL;  // Proportional Gain
    Ti : REAL;  // Integral Time (seconds)
    Td : REAL;  // Derivative Time (seconds)
    ciclo : TIME;  // Sampling period
END_VAR

VAR_OUTPUT
    CV : REAL;  // Control Variable (0.0 to 100.0)
END_VAR

VAR
    e : REAL;  // Error
    e_prev : REAL;  // Previous Error
    integral : REAL;  // Integral of error
    derivative : REAL;  // Derivative of error
    dt : TIME;  // Time difference
    dt_sec : REAL;  // Time difference in seconds
    integral_limit : REAL;  // Limit for integral to prevent windup
END_VAR

// Calculate error
e := SP - PV;

// Calculate time difference in seconds
dt := ciclo;
dt_sec := dt / 1.0s;  // Convert TIME to REAL seconds

// Proportional term
CV := Kp * e;

// Integral term
IF Ti > 0.0 THEN
    integral := integral + (e * dt_sec);
    integral_limit := 100.0 / Kp;
    IF CV >= 100.0 THEN
        integral := integral - (e * dt_sec);
    ELSIF CV <= 0.0 THEN
        integral := integral - (e * dt_sec);
    END_IF;
    CV := CV + (Kp / Ti) * integral;
END_IF;

// Derivative term
derivative := (e - e_prev) / dt_sec;
CV := CV + Kp * Td * derivative;

// Clamp CV to 0.0 to 100.0
IF CV > 100.0 THEN
    CV := 100.0;
ELSIF CV < 0.0 THEN
    CV := 0.0;
END_IF;

// Update previous error
e_prev := e;
END_FUNCTION_BLOCK
```