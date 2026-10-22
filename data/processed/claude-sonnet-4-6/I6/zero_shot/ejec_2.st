(* ── Cuerpo del bloque ─────────────────────────────────────────────────── *)

(* 1. Verificar rango del sensor *)
IF rawTemp < RAW_MIN OR rawTemp > RAW_MAX THEN

    almSensor := TRUE;   (* Activar alarma de sensor *)
    enfriador := FALSE;  (* Apagar enfriador por seguridad *)
    tempC     := 0.0;    (* Valor de temperatura indefinido → forzar a 0 *)

ELSE

    (* 2. Sin alarma de sensor *)
    almSensor := FALSE;

    (* 3. Escalar valor crudo a temperatura:
          tempC = (rawTemp - RAW_MIN) / (RAW_MAX - RAW_MIN) * (TEMP_MAX - TEMP_MIN) + TEMP_MIN
          Con RAW_MIN = 0 y TEMP_MIN = 0 se simplifica a:
          tempC = rawTemp / 27648.0 * 100.0                                *)
    tempC := (REAL#1.0 * rawTemp / REAL#27648.0) * (TEMP_MAX - TEMP_MIN) + TEMP_MIN;

    (* 4. Control con histéresis:
          - Activar  enfriador si tempC >= HYST_ON  (80.0 °C)
          - Desactivar         si tempC <= HYST_OFF (75.0 °C)
          - Entre ambos umbrales: conservar estado anterior (sin cambio)   *)
    IF tempC >= HYST_ON THEN
        enfriador := TRUE;
    ELSIF tempC <= HYST_OFF THEN
        enfriador := FALSE;
    (* ELSE: zona de histéresis → enfriador mantiene su estado actual *)
    END_IF;

END_IF;