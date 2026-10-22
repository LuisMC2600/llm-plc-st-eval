FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor crudo del sensor: 0..27648 → 0.0..100.0 °C *)
END_VAR

VAR_OUTPUT
    tempC     : REAL; (* Temperatura calculada en grados Celsius *)
    enfriador : BOOL; (* TRUE = enfriador activo *)
    almSensor : BOOL; (* TRUE = valor fuera de rango, alarma de sensor *)
END_VAR

VAR CONSTANT
    RAW_MIN  : INT  := 0;       (* Valor crudo mínimo válido *)
    RAW_MAX  : INT  := 27648;   (* Valor crudo máximo válido *)
    TEMP_MIN : REAL := 0.0;     (* Temperatura mínima del rango [°C] *)
    TEMP_MAX : REAL := 100.0;   (* Temperatura máxima del rango [°C] *)
    HYST_ON  : REAL := 80.0;    (* Umbral de activación del enfriador [°C] *)
    HYST_OFF : REAL := 75.0;    (* Umbral de desactivación del enfriador [°C] *)
END_VAR

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