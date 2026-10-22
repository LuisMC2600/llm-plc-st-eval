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
    RAW_MIN  : INT  := 0;       (* Valor crudo mínimo *)
    RAW_MAX  : INT  := 27648;   (* Valor crudo máximo *)
    TEMP_MIN : REAL := 0.0;     (* Temperatura mínima en °C *)
    TEMP_MAX : REAL := 100.0;   (* Temperatura máxima en °C *)
    HYST_ON  : REAL := 80.0;    (* Umbral de activación del enfriador *)
    HYST_OFF : REAL := 75.0;    (* Umbral de desactivación del enfriador *)
END_VAR

(* ------------------------------------------------------------------ *)
(* Lógica principal                                                     *)
(* ------------------------------------------------------------------ *)

(* 1. Verificar rango del sensor *)
IF rawTemp < RAW_MIN OR rawTemp > RAW_MAX THEN

    almSensor := TRUE;   (* Activar alarma de sensor *)
    enfriador := FALSE;  (* Apagar enfriador por seguridad *)
    tempC     := 0.0;    (* Valor de temperatura indefinido -> 0 *)

ELSE

    almSensor := FALSE;  (* Sensor en rango: sin alarma *)

    (* 2. Escalar rawTemp a grados Celsius (interpolación lineal)
          tempC = TEMP_MIN + (rawTemp - RAW_MIN) * (TEMP_MAX - TEMP_MIN)
                             / (RAW_MAX - RAW_MIN)
          Simplificado: tempC = rawTemp * 100.0 / 27648.0             *)
    tempC := INT_TO_REAL(rawTemp) * (TEMP_MAX - TEMP_MIN)
             / INT_TO_REAL(RAW_MAX - RAW_MIN);

    (* 3. Control con histéresis del enfriador
          - Activar  si tempC >= HYST_ON  (80.0 °C)
          - Desactivar si tempC <= HYST_OFF (75.0 °C)
          - Entre ambos umbrales: mantener estado anterior              *)
    IF tempC >= HYST_ON THEN
        enfriador := TRUE;
    ELSIF tempC <= HYST_OFF THEN
        enfriador := FALSE;
    (* ELSE: zona de histéresis -> enfriador conserva su estado actual *)
    END_IF;

END_IF;