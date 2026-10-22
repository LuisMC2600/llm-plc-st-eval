FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT;  (* Valor crudo del sensor: 0..27648 -> 0.0..100.0 °C *)
END_VAR

VAR_OUTPUT
    tempC     : REAL;  (* Temperatura calculada en grados Celsius *)
    enfriador : BOOL;  (* TRUE = enfriador activo *)
    almSensor : BOOL;  (* TRUE = señal fuera de rango *)
END_VAR

VAR CONSTANT
    RAW_MIN   : INT  := 0;       (* Valor crudo mínimo *)
    RAW_MAX   : INT  := 27648;   (* Valor crudo máximo *)
    TEMP_MIN  : REAL := 0.0;     (* Temperatura mínima en °C *)
    TEMP_MAX  : REAL := 100.0;   (* Temperatura máxima en °C *)
    HYST_HIGH : REAL := 80.0;    (* Umbral superior: activa enfriador *)
    HYST_LOW  : REAL := 75.0;    (* Umbral inferior: desactiva enfriador *)
END_VAR

(* ------------------------------------------------------------------ *)
(* Verificación de rango del sensor                                    *)
(* ------------------------------------------------------------------ *)
IF rawTemp < RAW_MIN OR rawTemp > RAW_MAX THEN
    almSensor := TRUE;   (* Señal fuera de rango: alarma activa *)
    enfriador := FALSE;  (* Apagar enfriador por seguridad *)
    tempC     := 0.0;    (* Valor de temperatura indefinido -> 0 *)

ELSE
    (* -------------------------------------------------------------- *)
    (* Señal válida: escalar rawTemp a grados Celsius                  *)
    (* Fórmula: tempC = (rawTemp / RAW_MAX) * (TEMP_MAX - TEMP_MIN)   *)
    (* -------------------------------------------------------------- *)
    almSensor := FALSE;
    tempC := (INT_TO_REAL(rawTemp) / INT_TO_REAL(RAW_MAX))
              * (TEMP_MAX - TEMP_MIN) + TEMP_MIN;

    (* -------------------------------------------------------------- *)
    (* Control con histéresis del enfriador                            *)
    (*   - Activa  si tempC >= HYST_HIGH (80.0 °C)                    *)
    (*   - Desactiva si tempC <= HYST_LOW  (75.0 °C)                  *)
    (*   - Entre ambos umbrales conserva el estado anterior            *)
    (* -------------------------------------------------------------- *)
    IF tempC >= HYST_HIGH THEN
        enfriador := TRUE;
    ELSIF tempC <= HYST_LOW THEN
        enfriador := FALSE;
    (* ELSE: zona de histéresis -> enfriador mantiene su estado *)
    END_IF;

END_IF;