## Lista de errores identificados

---

**Error 1 — Cálculo de escala con división entera antes de la conversión a REAL**

- **Línea:** `tempC := INT_TO_REAL(rawTemp / 27648 * 100);`
- **Por qué es un error:** `rawTemp` y `27648` son ambos `INT`, por lo que la división `rawTemp / 27648` se realiza en aritmética entera y produce **siempre 0** (salvo cuando `rawTemp = 27648`, donde da 1). El resultado se multiplica por 100 y *después* se convierte a `REAL`, perdiendo toda la precisión decimal.
- **Corrección:** Convertir primero a `REAL` y luego operar:
  ```
  tempC := INT_TO_REAL(rawTemp) / 27648.0 * 100.0;
  ```

---

**Error 2 — Lógica de histéresis invertida**

- **Líneas:** bloque `IF tempC >= 75.0 ... ELSIF tempC <= 80.0`
- **Por qué es un error:** Las condiciones están intercambiadas respecto a la especificación. Con esta lógica el enfriador se activa a 75 °C (debería activarse a 80 °C) y se desactiva a 80 °C (debería desactivarse a 75 °C). Además, la condición `ELSIF tempC <= 80.0` es siempre verdadera cuando la primera rama es falsa (`tempC < 75.0`), eliminando por completo la zona de histéresis.
- **Corrección:** Invertir los umbrales y las acciones:
  ```
  IF tempC >= 80.0 THEN
      enfriador := TRUE;
  ELSIF tempC <= 75.0 THEN
      enfriador := FALSE;
  END_IF
  ```

---

**Error 3 — Alarma de sensor no detecta valores negativos (rango incompleto)**

- **Línea:** `IF rawTemp > 27648 THEN`
- **Por qué es un error:** La especificación indica que el rango válido es **0 a 27648**. La condición actual solo detecta valores superiores a 27648, ignorando los valores negativos (`rawTemp < 0`), que también están fuera de rango y deben activar `almSensor`.
- **Corrección:**
  ```
  IF rawTemp < 0 OR rawTemp > 27648 THEN
  ```

---

**Error 4 — El enfriador no se desactiva ante alarma de sensor**

- **Sección:** bloque de gestión de `almSensor`
- **Por qué es un error:** La especificación exige que cuando se active `almSensor` el enfriador debe **desactivarse**. El código actual no incluye esa acción, por lo que el enfriador podría quedar encendido ante una lectura inválida.
- **Corrección:** Añadir el apagado del enfriador y el restablecimiento de la alarma dentro del bloque condicional:
  ```
  IF rawTemp < 0 OR rawTemp > 27648 THEN
      almSensor := TRUE;
      enfriador := FALSE;
  ELSE
      almSensor := FALSE;
  END_IF
  ```