FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP    : REAL;   (* Consigna / Set Point *)
    PV    : REAL;   (* Variable de proceso *)
    Kp    : REAL;   (* Ganancia proporcional *)
    Ti    : REAL;   (* Tiempo integral [s]; <= 0 desactiva integral *)
    Td    : REAL;   (* Tiempo derivativo [s] *)
    ciclo : TIME;   (* Período de muestreo *)
END_VAR

VAR_OUTPUT
    CV : REAL;      (* Salida de mando [0.0 .. 100.0] % *)
END_VAR

VAR
    e        : REAL;   (* Error actual: SP - PV *)
    e_prev   : REAL;   (* Error en el ciclo anterior *)
    integral : REAL;   (* Acumulador de la integral del error *)
    deriv    : REAL;   (* Término derivativo *)
    Ts       : REAL;   (* Período de muestreo en segundos *)
    CV_raw   : REAL;   (* Salida sin saturar *)
    saturado : BOOL;   (* TRUE si CV está saturada *)
END_VAR

(* ── 1. Período de muestreo ─────────────────────────────────────────── *)
(* Convierte TIME → segundos; TIME_TO_DINT devuelve milisegundos *)
Ts := DINT_TO_REAL(TIME_TO_DINT(ciclo)) / 1000.0;

(* Protección: si Ts <= 0 no se puede calcular *)
IF Ts <= 0.0 THEN
    RETURN;
END_IF;

(* ── 2. Error ────────────────────────────────────────────────────────── *)
e := SP - PV;

(* ── 3. Anti-windup por clamping ─────────────────────────────────────── *)
(* Determina si la salida anterior estaba saturada *)
saturado := (CV >= 100.0) OR (CV <= 0.0);

(* Acumula integral sólo si:
   - Ti > 0  (acción integral activa)
   - No está saturado, O el error tiende a desaturar:
       · saturado en 100 → no acumular error positivo (e > 0)
       · saturado en 0   → no acumular error negativo (e < 0)       *)
IF Ti > 0.0 THEN
    IF NOT saturado
       OR (CV >= 100.0 AND e < 0.0)
       OR (CV <= 0.0  AND e > 0.0)
    THEN
        integral := integral + e * Ts;
    END_IF;
END_IF;

(* ── 4. Término derivativo ───────────────────────────────────────────── *)
deriv := (e - e_prev) / Ts;

(* ── 5. Ley de control PID (forma estándar) ──────────────────────────── *)
(*  CV = Kp · ( e  +  (1/Ti)·∫e dt  +  Td·de/dt )                       *)
IF Ti > 0.0 THEN
    CV_raw := Kp * (e + (1.0 / Ti) * integral + Td * deriv);
ELSE
    (* Sin acción integral *)
    CV_raw := Kp * (e + Td * deriv);
END_IF;

(* ── 6. Saturación de la salida ──────────────────────────────────────── *)
IF CV_raw > 100.0 THEN
    CV := 100.0;
ELSIF CV_raw < 0.0 THEN
    CV := 0.0;
ELSE
    CV := CV_raw;
END_IF;

(* ── 7. Actualiza estado para el próximo ciclo ───────────────────────── *)
e_prev := e;

END_FUNCTION_BLOCK