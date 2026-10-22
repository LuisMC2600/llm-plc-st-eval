```pascal
FUNCTION_BLOCK FB_Temperatura
VAR_INPUT
    rawTemp : INT;      (* Valor crudo del sensor: 0..27648 -> 0.0..100.0 °C *)
END_VAR

VAR_OUTPUT
    tempC     : REAL;   (* Temperatura calculada en grados Celsius *)
    enfriador : BOOL;   (* TRUE = enfriador activo *)
    almSensor : BOOL;   (* TRUE = señal fuera de rango, alarma de sensor *)
END_VAR

VAR CONSTANT
    RAW_MIN   : INT  := 0;       (* Valor crudo mínimo válido *)
    RAW_MAX   : INT  := 27648;   (* Valor crudo máximo válido *)
    TEMP_MIN  : REAL := 0.0;     (* Temperatura mínima del rango *)
    TEMP_MAX  : REAL := 100.0;   (* Temperatura máxima del rango *)
    HYST_HIGH : REAL := 80.0;    (* Umbral superior: activa enfriador *)
    HYST_LOW  : REAL := 75.0;    (* Umbral inferior: desactiva enfriador *)
END_VAR
```
```pascal
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
```

---

### Notas de diseño

| Aspecto | Decisión |
|---|---|
| **Escalado** | Conversión lineal `rawTemp × 100 / 27648`; se usan `INT_TO_REAL` para evitar división entera. |
| **Histéresis** | Estructura `IF / ELSIF` sin rama `ELSE` en la zona intermedia: la variable `enfriador` retiene su valor anterior (memoria implícita de la instancia del FB). |
| **Alarma de sensor** | Fuerza `enfriador := FALSE` y `tempC := 0.0` para un estado seguro y determinista. |
| **Estándar** | Declaración de constantes con `VAR CONSTANT`, tipos explícitos, sin extensiones propietarias. |