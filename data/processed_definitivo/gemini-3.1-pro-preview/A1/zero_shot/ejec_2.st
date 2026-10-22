FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP : REAL;      // Consigna (Setpoint)
    PV : REAL;      // Variable de proceso
    Kp : REAL;      // Ganancia proporcional
    Ti : REAL;      // Tiempo integral (segundos)
    Td : REAL;      // Tiempo derivativo (segundos)
    ciclo : TIME;   // Período de muestreo
END_VAR

VAR_OUTPUT
    CV : REAL;      // Variable de control (0.0 a 100.0 %)
END_VAR

VAR
    e : REAL;           // Error actual
    e_prev : REAL;      // Error del ciclo anterior
    de_dt : REAL;       // Derivada del error
    dt : REAL;          // Tiempo de ciclo en segundos
    I_sum : REAL;       // Sumatoria de la integral del error
    I_new : REAL;       // Valor tentativo de la integral
    CV_tentative : REAL;// Salida tentativa para evaluar saturación
END_VAR

// Convertir tiempo de ciclo a segundos (REAL)
dt := TIME_TO_REAL(ciclo) / 1000.0;

// Evitar división por cero si el tiempo de ciclo es muy pequeño o cero
IF dt <= 0.0 THEN
    dt := 0.001;
END_IF;

// Cálculo del error (Acción directa: CV aumenta si PV < SP)
e := SP - PV;

// Cálculo de la derivada del error
de_dt := (e - e_prev) / dt;

// Acción Integral con Anti-windup (Clamping)
IF Ti > 0.0 THEN
    // Calcular integral tentativa
    I_new := I_sum + (e * dt);

    // Calcular salida tentativa para evaluar saturación
    CV_tentative := Kp * (e + (I_new / Ti) + (Td * de_dt));

    // Lógica de Clamping: evitar acumulación si satura en la misma dirección del error
    IF (CV_tentative >= 100.0 AND e > 0.0) OR (CV_tentative <= 0.0 AND e < 0.0) THEN
        // No se actualiza I_sum (se congela la integral)
    ELSE
        I_sum := I_new; // Se actualiza la integral
    END_IF;
ELSE
    I_sum := 0.0; // Desactivar acción integral si Ti <= 0.0
END_IF;

// Cálculo de la salida final (CV) antes de límites
IF Ti > 0.0 THEN
    CV := Kp * (e + (I_sum / Ti) + (Td * de_dt));
ELSE
    CV := Kp * (e + (Td * de_dt));
END_IF;

// Limitar la salida al rango 0.0 - 100.0 %
IF CV > 100.0 THEN
    CV := 100.0;
ELSIF CV < 0.0 THEN
    CV := 0.0;
END_IF;

// Guardar el error actual para el cálculo derivativo del próximo ciclo
e_prev := e;

END_FUNCTION_BLOCK