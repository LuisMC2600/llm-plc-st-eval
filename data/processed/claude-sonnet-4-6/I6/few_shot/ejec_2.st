FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT; (* Valor crudo del sensor: 0..27648 -> 0.0..100.0 °C *)
END_VAR
VAR_OUTPUT
    tempC     : REAL; (* Temperatura calculada en grados Celsius *)
    enfriador : BOOL; (* Salida del enfriador *)
    almSensor : BOOL; (* Alarma de sensor fuera de rango *)
END_VAR
VAR CONSTANT
    RAW_MIN  : INT  := 0;       (* Valor crudo minimo valido *)
    RAW_MAX  : INT  := 27648;   (* Valor crudo maximo valido *)
    TEMP_MAX : REAL := 100.0;   (* Temperatura maxima de escala *)
    HIS_ON   : REAL := 80.0;    (* Umbral de activacion del enfriador *)
    HIS_OFF  : REAL := 75.0;    (* Umbral de desactivacion del enfriador *)
END_VAR

(* --- Verificacion de rango del sensor --- *)
IF rawTemp < RAW_MIN OR rawTemp > RAW_MAX THEN
    almSensor := TRUE;   (* Fuera de rango: activa alarma *)
    enfriador := FALSE;  (* Apaga el enfriador por seguridad *)
    tempC     := 0.0;    (* Valor de temperatura indefinido *)
ELSE
    almSensor := FALSE;

    (* --- Conversion lineal: rawTemp -> grados Celsius --- *)
    (* tempC = (rawTemp / 27648) * 100.0                   *)
    tempC := (INT_TO_REAL(rawTemp) / INT_TO_REAL(RAW_MAX)) * TEMP_MAX;

    (* --- Control con histeresis --- *)
    IF tempC >= HIS_ON THEN
        enfriador := TRUE;   (* Supera umbral alto: enciende enfriador *)
    ELSIF tempC <= HIS_OFF THEN
        enfriador := FALSE;  (* Baja del umbral bajo: apaga enfriador *)
    (* Entre 75.0 y 80.0: conserva el estado anterior (histeresis) *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK