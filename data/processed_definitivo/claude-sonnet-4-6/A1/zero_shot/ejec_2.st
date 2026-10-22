FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP    : REAL;   (* Setpoint / consigna *)
    PV    : REAL;   (* Process variable / variable de proceso *)
    Kp    : REAL;   (* Ganancia proporcional *)
    Ti    : REAL;   (* Tiempo integral [s]; <= 0 desactiva integral *)
    Td    : REAL;   (* Tiempo derivativo [s] *)
    ciclo : TIME;   (* Período de muestreo *)
END_VAR

VAR_OUTPUT
    CV : REAL;      (* Salida de control [0.0 .. 100.0] % *)
END_VAR

VAR
    e_prev    : REAL;   (* Error en la iteración anterior *)
    integral  : REAL;   (* Acumulador de la integral del error *)
    Ts        : REAL;   (* Período de muestreo en segundos *)
    e         : REAL;   (* Error actual: SP - PV *)
    P_term    : REAL;   (* Término proporcional *)
    I_term    : REAL;   (* Término integral *)
    D_term    : REAL;   (* Término derivativo *)
    CV_raw    : REAL;   (* Salida sin saturar *)
    saturated : BOOL;   (* TRUE si CV está saturada *)
    sat_high  : BOOL;   (* TRUE si saturada en límite superior *)
    sat_low   : BOOL;   (* TRUE si saturada en límite inferior *)
END_VAR

(* ── Constantes de saturación ── *)
VAR CONSTANT
    CV_MAX : REAL := 100.0;
    CV_MIN : REAL := 0.0;
END_VAR

(* ─────────────────────────────────────────────────────────────
   1. Convertir período de muestreo de TIME a segundos (REAL)
   ───────────────────────────────────────────────────────────── *)
Ts := TIME_TO_REAL(ciclo) / 1000.0;   (* TIME está en ms en IEC 61131-3 *)

(* Protección: Ts debe ser positivo *)
IF Ts <= 0.0 THEN
    Ts := 0.001;   (* 1 ms mínimo para evitar división por cero *)
END_IF;

(* ─────────────────────────────────────────────────────────────
   2. Calcular error actual
   ───────────────────────────────────────────────────────────── *)
e := SP - PV;

(* ─────────────────────────────────────────────────────────────
   3. Detectar estado de saturación del ciclo anterior
   ───────────────────────────────────────────────────────────── *)
sat_high  := (CV >= CV_MAX);
sat_low   := (CV <= CV_MIN);
saturated := sat_high OR sat_low;

(* ─────────────────────────────────────────────────────────────
   4. Acumulación integral con anti-windup por clamping
      - Si saturado en máximo: no acumular error positivo
      - Si saturado en mínimo: no acumular error negativo
   ───────────────────────────────────────────────────────────── *)
IF Ti > 0.0 THEN
    IF NOT ((sat_high AND (e > 0.0)) OR (sat_low AND (e < 0.0))) THEN
        integral := integral + e * Ts;   (* Integración rectangular hacia adelante *)
    END_IF;
END_IF;

(* ─────────────────────────────────────────────────────────────
   5. Calcular términos PID
   ───────────────────────────────────────────────────────────── *)
(* Término proporcional *)
P_term := e;

(* Término integral (desactivado si Ti <= 0) *)
IF Ti > 0.0 THEN
    I_term := (1.0 / Ti) * integral;
ELSE
    I_term := 0.0;
END_IF;

(* Término derivativo: diferencia hacia atrás del error *)
D_term := Td * (e - e_prev) / Ts;

(* ─────────────────────────────────────────────────────────────
   6. Calcular salida sin saturar
   ───────────────────────────────────────────────────────────── *)
CV_raw := Kp * (P_term + I_term + D_term);

(* ─────────────────────────────────────────────────────────────
   7. Saturar salida al rango [0.0, 100.0]
   ───────────────────────────────────────────────────────────── *)
IF CV_raw >= CV_MAX THEN
    CV := CV_MAX;
ELSIF CV_raw <= CV_MIN THEN
    CV := CV_MIN;
ELSE
    CV := CV_raw;
END_IF;

(* ─────────────────────────────────────────────────────────────
   8. Guardar error para el siguiente ciclo
   ───────────────────────────────────────────────────────────── *)
e_prev := e;