FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;      // Consigna (Setpoint)
    PV : REAL;      // Variable de proceso (Process Variable)
    Kp : REAL;      // Ganancia proporcional
    Ti : REAL;      // Tiempo integral (segundos)
    Td : REAL;      // Tiempo derivativo (segundos)
    ciclo : TIME;   // Período de muestreo
END_VAR

VAR_OUTPUT
    CV : REAL;      // Variable de control (0.0 a 100.0 %)
END_VAR

VAR
    e : REAL;                   // Error actual
    e_prev : REAL := 0.0;       // Error del ciclo anterior
    integral_sum : REAL := 0.0; // Sumatoria de la integral del error
    dt : REAL;                  // Tiempo de ciclo en segundos
    P_term : REAL;              // Término proporcional
    I_term : REAL;              // Término integral
    D_term : REAL;              // Término derivativo
    CV_pre : REAL;              // Salida preliminar para evaluar saturación
    CV_raw : REAL;              // Salida calculada sin limitar
END_VAR

// Convertir el tiempo de ciclo a segundos
dt := TIME_TO_REAL(ciclo) / 1000.0;

// Cálculo del error (salida aumenta si PV < SP)
e := SP - PV;

// Cálculo del término proporcional
P_term := Kp * e;

// Cálculo del término derivativo (sobre el error)
IF dt > 0.0 THEN
    D_term := Kp * Td * (e - e_prev) / dt;
ELSE
    D_term := 0.0;
END_IF;

// Cálculo del término integral y Anti-windup (Clamping)
IF Ti > 0.0 THEN
    // Calcular salida preliminar con la integral del ciclo anterior
    I_term := (Kp / Ti) * integral_sum;
    CV_pre := P_term + I_term + D_term;
    
    // Anti-windup: evitar acumular error si la salida está saturada en la misma dirección
    IF (CV_pre >= 100.0 AND e > 0.0) OR (CV_pre <= 0.0 AND e < 0.0) THEN
        // No se acumula el error (Clamping activo)
    ELSE
        // Se acumula el error en la integral
        IF dt > 0.0 THEN
            integral_sum := integral_sum + (e * dt);
        END_IF;
    END_IF;
    
    // Recalcular el término integral con el valor actualizado
    I_term := (Kp / Ti) * integral_sum;
ELSE
    // Desactivar acción integral si Ti <= 0.0
    integral_sum := 0.0;
    I_term := 0.0;
END_IF;

// Suma total de la ecuación PID estándar
CV_raw := P_term + I_term + D_term;

// Limitación de la salida (0.0 a 100.0)
IF CV_raw > 100.0 THEN
    CV := 100.0;
ELSIF CV_raw < 0.0 THEN
    CV := 0.0;
ELSE
    CV := CV_raw;
END_IF;

// Actualizar el error para el cálculo derivativo del próximo ciclo
e_prev := e;

END_FUNCTION_BLOCK