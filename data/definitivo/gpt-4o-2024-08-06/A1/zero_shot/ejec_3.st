```pascal
FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;      // Setpoint
    PV : REAL;      // Process Variable
    Kp : REAL;      // Proportional Gain
    Ti : REAL;      // Integral Time (seconds)
    Td : REAL;      // Derivative Time (seconds)
    ciclo : TIME;   // Sampling Time
END_VAR

VAR_OUTPUT
    CV : REAL;      // Control Variable (0.0 to 100.0)
END_VAR

VAR
    e : REAL;               // Error
    e_prev : REAL;          // Previous Error
    integral : REAL;        // Integral Term
    derivative : REAL;      // Derivative Term
    dt : REAL;              // Sampling Time in seconds
    CV_unsat : REAL;        // Unsaturated Control Variable
END_VAR

VAR CONSTANT
    CV_MIN : REAL := 0.0;   // Minimum CV
    CV_MAX : REAL := 100.0; // Maximum CV
END_VAR

// Convert TIME to seconds
dt := REAL_TO_TIME(ciclo) / 1000.0;

// Calculate error
e := SP - PV;

// Proportional term
CV_unsat := Kp * e;

// Integral term
IF Ti > 0.0 THEN
    integral := integral + (e * dt / Ti);
    
    // Anti-windup: Clamping
    IF (CV_unsat >= CV_MAX) AND (e > 0.0) THEN
        integral := integral; // Do not accumulate positive error
    ELSIF (CV_unsat <= CV_MIN) AND (e < 0.0) THEN
        integral := integral; // Do not accumulate negative error
    ELSE
        CV_unsat := CV_unsat + Kp * integral;
    END_IF
END_IF

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
```

Este código implementa un controlador PID discreto en Structured Text (ST) conforme al estándar IEC 61131-3. El controlador utiliza la forma estándar del PID y aplica técnicas de anti-windup para evitar la acumulación excesiva de la acción integral cuando la salida está saturada.