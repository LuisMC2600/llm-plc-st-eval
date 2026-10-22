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
(* Verificación de rango de la señal cruda                            *)
(* ------------------------------------------------------------------ *)
IF rawTemp < RAW_MIN OR rawTemp > RAW_MAX THEN
    almSensor := TRUE;   (* Activar alarma de sensor *)
    enfriador := FALSE;  (* Apagar enfriador por seguridad *)
    tempC     := 0.0;    (* Valor de temperatura indefinido -> 0 *)
    RETURN;              (* Salir sin continuar el procesamiento *)
END_IF;

(* ------------------------------------------------------------------ *)
(* Señal válida: limpiar alarma                                        *)
(* ------------------------------------------------------------------ *)
almSensor := FALSE;

(* ------------------------------------------------------------------ *)
(* Escalado lineal: rawTemp (0..27648) -> tempC (0.0..100.0 °C)       *)
(* Fórmula: tempC = (rawTemp - RAW_MIN) / (RAW_MAX - RAW_MIN)         *)
(*                  * (TEMP_MAX - TEMP_MIN) + TEMP_MIN                *)
(* ------------------------------------------------------------------ *)
tempC := (INT_TO_REAL(rawTemp) - INT_TO_REAL(RAW_MIN))
         / (INT_TO_REAL(RAW_MAX) - INT_TO_REAL(RAW_MIN))
         * (TEMP_MAX - TEMP_MIN)
         + TEMP_MIN;

(* ------------------------------------------------------------------ *)
(* Control con histéresis del enfriador                               *)
(*   - Activar  si tempC >= HYST_ON  (80.0 °C)                        *)
(*   - Desactivar si tempC <= HYST_OFF (75.0 °C)                      *)
(*   - Entre 75.0 y 80.0 conserva el estado anterior (sin oscilar)    *)
(* ------------------------------------------------------------------ *)
IF tempC >= HYST_ON THEN
    enfriador := TRUE;   (* Temperatura alta: encender enfriador *)
ELSIF tempC <= HYST_OFF THEN
    enfriador := FALSE;  (* Temperatura baja: apagar enfriador *)
(* ELSE: zona de histéresis -> enfriador mantiene su estado actual *)
END_IF;

END_FUNCTION_BLOCK