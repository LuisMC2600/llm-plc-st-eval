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
    integral : REAL;  // Integral of Error
    derivative : REAL;  // Derivative of Error
    dt : TIME;  // Time difference
END_VAR

// Initialize variables
IF ciclo > T#0s THEN
    dt := ciclo;
ELSE
    dt := T#1s;  // Avoid division by zero
END_IF

// Calculate error
e := SP - PV;

// Proportional term
CV := Kp * e;

// Integral term
IF Ti > 0.0 THEN
    integral := integral + (e * dt / Ti);
ELSE
    integral := 0.0;  // Integral action disabled
END_IF

// Derivative term
derivative := (e - e_prev) / dt;

// PID output
CV := CV + integral + (Kp * Td * derivative);

// Anti-windup by clamping
IF CV > 100.0 THEN
    CV := 100.0;
    IF e > 0.0 THEN
        integral := integral - e;  // Prevent integral windup
    END_IF
ELSIF CV < 0.0 THEN
    CV := 0.0;
    IF e < 0.0 THEN
        integral := integral - e;  // Prevent integral windup
    END_IF
END_IF;

// Update previous error
e_prev := e;
END_FUNCTION_BLOCK
```