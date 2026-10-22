## Lista de errores identificados

---

**Error 1 — Línea de escalado: división entera antes de la conversión a REAL**

- **Ubicación:** `tempC := INT_TO_REAL(rawTemp / 27648 * 100);`
- **Por qué es un error:** `rawTemp` es `INT` y `27648` es una constante entera, por lo que el operador `/` realiza división entera. Para cualquier valor de `rawTemp` menor que `27648`, el resultado de `rawTemp / 27648` es `0` (truncamiento), y `0 * 100` es `0`. La conversión a `REAL` ocurre al final, cuando la información ya se perdió. La salida `tempC` será siempre `0.0` salvo cuando `rawTemp = 27648`.
- **Corrección:** Convertir `rawTemp` a `REAL` primero y usar constantes reales para que toda la aritmética sea en punto flotante:
  ```
  tempC := INT_TO_REAL(rawTemp) / 27648.0 * 100.0;
  ```

---

**Error 2 — Lógica de histéresis invertida**

- **Ubicación:** Bloque `IF tempC >= 75.0 ... ELSIF tempC <= 80.0`
- **Por qué es un error:** Las condiciones están intercambiadas respecto al requisito. El enfriador debe **activarse** al llegar a **80.0** y **desactivarse** al bajar a **75.0**. El código actual lo activa con ≥ 75.0 y lo desactiva con ≤ 80.0, lo que invierte completamente el comportamiento deseado. Además, ambas condiciones se solapan en el rango 75.0–80.0, por lo que la rama `ELSIF` nunca se evalúa cuando la primera ya es verdadera.
- **Corrección:** Invertir los umbrales y las acciones:
  ```
  IF tempC >= 80.0 THEN
      enfriador := TRUE;
  ELSIF tempC <= 75.0 THEN
      enfriador := FALSE;
  END_IF
  ```
  Así, entre 75.0 y 80.0 ninguna rama se ejecuta y el estado anterior se conserva (histéresis correcta).

---

**Error 3 — Condición de alarma incompleta: no detecta valores negativos**

- **Ubicación:** `IF rawTemp > 27648 THEN`
- **Por qué es un error:** El requisito indica que `rawTemp` fuera del rango **0 a 27648** debe activar `almSensor`. El código solo comprueba el límite superior (`> 27648`) e ignora los valores negativos (`rawTemp < 0`), que son posibles porque `rawTemp` es de tipo `INT` (puede tomar valores negativos).
- **Corrección:** Añadir la comprobación del límite inferior:
  ```
  IF rawTemp < 0 OR rawTemp > 27648 THEN
      almSensor := TRUE;
  END_IF
  ```

---

**Error 4 — Alarma activa no desactiva el enfriador ni se resetea**

- **Ubicación:** Bloque `IF rawTemp > 27648` (gestión de `almSensor`)
- **Por qué es un error:** El requisito establece que cuando `almSensor` se activa, el enfriador debe **desactivarse**. El código no incluye esa acción. Además, `almSensor` nunca se pone a `FALSE`, por lo que una vez activada la alarma permanece latched indefinidamente aunque `rawTemp` vuelva al rango válido.
- **Corrección:** Gestionar ambos casos en una estructura `IF/ELSE`:
  ```
  IF rawTemp < 0 OR rawTemp > 27648 THEN
      almSensor  := TRUE;
      enfriador  := FALSE;
  ELSE
      almSensor  := FALSE;
  END_IF
  ```