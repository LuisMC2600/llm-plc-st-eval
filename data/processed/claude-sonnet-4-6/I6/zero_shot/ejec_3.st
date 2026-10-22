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
(* 1. Verificación de rango del sensor                                 *)
(* ------------------------------------------------------------------ *)
IF rawTemp < RAW_MIN OR rawTemp > RAW_MAX THEN
    almSensor := TRUE;   (* Señal fuera de rango: alarma activa *)
    enfriador := FALSE;  (* Apagar enfriador por seguridad *)
    (* tempC conserva el último valor válido calculado *)
    RETURN;              (* Salir sin procesar más lógica *)
END_IF;

(* Sin alarma de sensor *)
almSensor := FALSE;

(* ------------------------------------------------------------------ *)
(* 2. Escalado lineal: rawTemp -> tempC                                *)
(*    tempC = (rawTemp - RAW_MIN) / (RAW_MAX - RAW_MIN) * TEMP_MAX    *)
(* ------------------------------------------------------------------ *)
tempC := (INT_TO_REAL(rawTemp) - INT_TO_REAL(RAW_MIN))
         / (INT_TO_REAL(RAW_MAX) - INT_TO_REAL(RAW_MIN))
         * (TEMP_MAX - TEMP_MIN)
         + TEMP_MIN;

(* ------------------------------------------------------------------ *)
(* 3. Control con histéresis del enfriador                             *)
(*    >= 80.0 °C -> encender  |  <= 75.0 °C -> apagar                 *)
(*    Entre 75.0 y 80.0 °C   -> mantener estado anterior              *)
(* ------------------------------------------------------------------ *)
IF tempC >= HYST_HIGH THEN
    enfriador := TRUE;   (* Temperatura alta: activar enfriador *)
ELSIF tempC <= HYST_LOW THEN
    enfriador := FALSE;  (* Temperatura baja: desactivar enfriador *)
(* ELSE: zona de histéresis, enfriador conserva su estado *)
END_IF;