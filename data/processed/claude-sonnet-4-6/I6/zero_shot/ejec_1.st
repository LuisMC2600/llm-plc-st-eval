(* ── Cuerpo del FUNCTION_BLOCK ── *)

(* 1. Verificar rango válido del sensor *)
IF rawTemp < RAW_MIN OR rawTemp > RAW_MAX THEN

    almSensor := TRUE;   (* Activar alarma de sensor fuera de rango *)
    enfriador := FALSE;  (* Desactivar enfriador por seguridad *)
    tempC     := 0.0;    (* Valor de temperatura indefinido, se fuerza a 0 *)

ELSE

    (* 2. Sin alarma: señal dentro de rango *)
    almSensor := FALSE;

    (* 3. Escalar rawTemp a grados Celsius (regla de tres lineal)
          tempC = (rawTemp - RAW_MIN) / (RAW_MAX - RAW_MIN) * (TEMP_MAX - TEMP_MIN) + TEMP_MIN
          Simplificado: tempC = rawTemp * 100.0 / 27648.0                              *)
    tempC := REAL_TO_REAL(INT_TO_REAL(rawTemp)) * (TEMP_MAX - TEMP_MIN)
             / INT_TO_REAL(RAW_MAX - RAW_MIN) + TEMP_MIN;

    (* 4. Control con histéresis (biestable):
          - Activa enfriador si tempC >= HYST_HIGH
          - Desactiva enfriador si tempC <= HYST_LOW
          - Entre ambos umbrales conserva el estado anterior (sin oscilar) *)
    IF tempC >= HYST_HIGH THEN
        enfriador := TRUE;
    ELSIF tempC <= HYST_LOW THEN
        enfriador := FALSE;
    (* ELSE: zona de histéresis -> enfriador mantiene su estado previo *)
    END_IF;

END_IF;