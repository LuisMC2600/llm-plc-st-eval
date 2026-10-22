## Lista de errores identificados

---

**Error 1 — Línea de escalado: división entera antes de la conversión a REAL**

- **Dónde:** `tempC := INT_TO_REAL(rawTemp / 27648 * 100);`
- **Por qué es un error:** `rawTemp` es `INT` y `27648` es una literal entera, por lo que `/` ejecuta división entera. Para cualquier valor de `rawTemp` menor que `27648`, el cociente es `0`, y el resultado siempre será `0.0` salvo cuando `rawTemp = 27648`. La conversión a `REAL` ocurre demasiado tarde, cuando la precisión ya se perdió.
- **Corrección propuesta:** Convertir primero a `REAL` y usar literales reales para forzar aritmética en punto flotante:
  ```
  tempC := INT_TO_REAL(rawTemp) / 27648.0 * 100.0;
  ```

---

**Error 2 — Lógica de histéresis invertida**

- **Dónde:** Bloque `IF tempC >= 75.0 ... ELSIF tempC <= 80.0`
- **Por qué es un error:** Las condiciones están intercambiadas respecto a la especificación. La rama `TRUE` se activa con `tempC >= 75.0` (umbral de apagado) y la rama `FALSE` con `tempC <= 80.0` (umbral de encendido). Esto invierte el comportamiento: el enfriador se encendería demasiado pronto y se apagaría demasiado tarde. Además, ambas condiciones se solapan en el rango 75–80, pero como `ELSIF` solo evalúa si la primera es falsa, en ese rango intermedio el enfriador siempre se activaría, eliminando la histéresis.
- **Corrección propuesta:** Intercambiar los umbrales y las acciones:
  ```
  IF tempC >= 80.0 THEN
      enfriador := TRUE;
  ELSIF tempC <= 75.0 THEN
      enfriador := FALSE;
  END_IF
  ```

---

**Error 3 — Alarma no detecta valores negativos (rango incompleto)**

- **Dónde:** `IF rawTemp > 27648 THEN almSensor := TRUE; END_IF`
- **Por qué es un error:** Solo se comprueba el límite superior. La especificación indica que `rawTemp` fuera del rango `0–27648` debe activar `almSensor`, pero valores negativos (posibles en `INT`) no son detectados.
- **Corrección propuesta:**
  ```
  IF rawTemp < 0 OR rawTemp > 27648 THEN
      almSensor := TRUE;
  END_IF
  ```

---

**Error 4 — La alarma nunca se desactiva**

- **Dónde:** Mismo bloque `IF rawTemp > 27648 THEN almSensor := TRUE; END_IF`
- **Por qué es un error:** No existe rama `ELSE` ni condición que ponga `almSensor := FALSE`. Una vez activada, la alarma permanece encendida indefinidamente aunque `rawTemp` vuelva al rango válido, lo que impide la recuperación automática.
- **Corrección propuesta:** Añadir la rama `ELSE`:
  ```
  IF rawTemp < 0 OR rawTemp > 27648 THEN
      almSensor := TRUE;
  ELSE
      almSensor := FALSE;
  END_IF
  ```

---

**Error 5 — El enfriador no se apaga ante condición de alarma**

- **Dónde:** Bloque de alarma (ausencia de lógica de seguridad)
- **Por qué es un error:** La especificación exige que cuando se active `almSensor` el enfriador se desactive, pero no existe ninguna instrucción que fuerce `enfriador := FALSE` en ese caso. El enfriador podría quedar activo con una señal de sensor inválida.
- **Corrección propuesta:** Forzar el apagado del enfriador dentro del bloque de alarma:
  ```
  IF rawTemp < 0 OR rawTemp > 27648 THEN
      almSensor := TRUE;
      enfriador := FALSE;
  ELSE
      almSensor := FALSE;
  END_IF
  ```