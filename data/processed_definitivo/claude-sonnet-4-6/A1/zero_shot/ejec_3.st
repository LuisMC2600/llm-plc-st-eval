FUNCTION_BLOCK FB_PID
VAR_INPUT
    SP    : REAL;   (* Consigna / Set Point *)
    PV    : REAL;   (* Variable de proceso / Process Variable *)
    Kp    : REAL;   (* Ganancia proporcional *)
    Ti    : REAL;   (* Tiempo integral [s]; <= 0 desactiva integral *)
    Td    : REAL;   (* Tiempo derivativo [s] *)
    ciclo : TIME;   (* Período de muestreo *)
END_VAR

VAR_OUTPUT
    CV : REAL;      (* Salida de control [0.0 .. 100.0] % *)
END_VAR

VAR
    e_prev    : REAL;   (* Error en el ciclo anterior *)
    integral  : REAL;   (* Acumulador de la integral del error *)
    dt        : REAL;   (* Período de muestreo en segundos *)
    e         : REAL;   (* Error actual: SP - PV *)
    P_term    : REAL;   (* Término proporcional *)
    I_term    : REAL;   (* Término integral *)
    D_term    : REAL;   (* Término derivativo *)
    CV_raw    : REAL;   (* Salida sin saturar *)
    saturated : BOOL;   (* TRUE si CV está saturada *)
    clamp_ok  : BOOL;   (* TRUE si se permite acumular integral *)
END_VAR

(* ── 1. Período de muestreo en segundos ─────────────────────────────── *)
dt := TIME_TO_REAL(ciclo) / 1000.0;   (* TIME está en ms en IEC 61131-3 *)

(* ── 2. Error actual ────────────────────────────────────────────────── *)
e := SP - PV;

(* ── 3. Término proporcional ────────────────────────────────────────── *)
P_term := e;

(* ── 4. Término integral con anti-windup por clamping ───────────────── *)
IF Ti > 0.0 THEN
    (* Determinar si la integración está permitida (anti-windup) *)
    (* Bloquear acumulación si CV saturada en máx y error positivo,  *)
    (* o si CV saturada en mín y error negativo.                      *)
    saturated := (CV >= 100.0) OR (CV <= 0.0);

    clamp_ok := NOT saturated                          (* sin saturación: siempre OK *)
                OR (CV >= 100.0 AND e < 0.0)          (* saturado alto, error baja  *)
                OR (CV <= 0.0  AND e > 0.0);           (* saturado bajo, error sube  *)

    IF clamp_ok THEN
        integral := integral + e * dt;
    END_IF;

    I_term := (1.0 / Ti) * integral;
ELSE
    (* Acción integral desactivada *)
    integral := 0.0;
    I_term   := 0.0;
END_IF;

(* ── 5. Término derivativo (diferencia hacia atrás sobre el error) ──── *)
IF dt > 0.0 THEN
    D_term := Td * (e - e_prev) / dt;
ELSE
    D_term := 0.0;
END_IF;

(* ── 6. Salida PID en forma estándar: CV = Kp·(e + I_term + D_term) ── *)
CV_raw := Kp * (P_term + I_term + D_term);

(* ── 7. Saturación de la salida [0.0 .. 100.0] % ───────────────────── *)
IF CV_raw > 100.0 THEN
    CV := 100.0;
ELSIF CV_raw < 0.0 THEN
    CV := 0.0;
ELSE
    CV := CV_raw;
END_IF;

(* ── 8. Guardar error para el próximo ciclo ─────────────────────────── *)
e_prev := e;

END_FUNCTION_BLOCK