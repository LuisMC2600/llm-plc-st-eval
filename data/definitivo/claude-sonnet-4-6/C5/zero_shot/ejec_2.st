# Análisis de errores lógicos en FB_EstrellaTriangulo

---

**Error 1 — Estado 1: `kD` se activa antes de desconectar `kY` (violación del enclavamiento)**

- **Dónde:** Estado `1`, dentro del bloque `IF t1.Q THEN`.
- **Por qué es un error:** En cuanto `t1.Q` se pone a `TRUE`, el código asigna `kD := TRUE` sin haber desactivado `kY` previamente. En ese mismo ciclo de scan ambas salidas están activas simultáneamente, lo que viola el requisito de que `kY` y `kD` jamás deben estar activos al mismo tiempo (riesgo de cortocircuito entre bobinados).
- **Corrección:** Al detectar `t1.Q`, únicamente desactivar `kY` y avanzar al estado de tiempo muerto; activar `kD` solo después de que transcurra el tiempo muerto.

---

**Error 2 — Ausencia de tiempo muerto entre la desconexión de `kY` y la conexión de `kD`**

- **Dónde:** Transición entre estados `1` y `2`; el temporizador `t2` está declarado pero nunca se usa.
- **Por qué es un error:** El requisito exige 100 ms de tiempo muerto antes de conectar `kD`. El código pasa directamente de desactivar `kY` a activar `kD` en el mismo ciclo (o en el ciclo inmediatamente siguiente), sin ninguna espera. El temporizador `t2` declarado en `VAR` queda completamente inutilizado.
- **Corrección:** Introducir un estado intermedio (p. ej. estado `2`) en el que se arranque `t2` con `PT := T#100MS`; solo cuando `t2.Q = TRUE` se pasa a un nuevo estado (p. ej. estado `3`) donde se activa `kD`.

---

**Error 3 — Estado 2: `kY` se desactiva demasiado tarde y el estado no tiene continuidad**

- **Dónde:** Estado `2`, instrucción `kY := FALSE`.
- **Por qué es un error:** Con la lógica actual, `kY` se desactiva en el estado `2`, pero `kD` ya fue activado en el estado `1` (ver Error 1), por lo que la desactivación llega un ciclo tarde. Además, el estado `2` no activa `kD` (que ya estaba mal activado antes), no arranca ningún temporizador ni avanza a ningún estado posterior, dejando la máquina de estados bloqueada en `2` indefinidamente sin ninguna acción útil.
- **Corrección:** Reestructurar los estados de forma que: en el estado de transición se desactive `kY` y se inicie `t2`; en el estado siguiente (tras `t2.Q`) se active `kD` y se permanezca ahí hasta que se pulse `btnParo`.

---

**Error 4 — El temporizador `t1` no se resetea al salir del estado `1`**

- **Dónde:** Estado `1`, llamada a `t1(IN := TRUE, PT := T#8S)`.
- **Por qué es un error:** `t1` solo se llama con `IN := TRUE` mientras se está en el estado `1`. Al cambiar de estado, `t1` deja de ser invocado, por lo que su entrada `IN` queda implícitamente a `FALSE` (valor por defecto de `BOOL`) y el temporizador se resetea solo de forma indirecta. Esto es funcionalmente frágil: si en alguna revisión del código se llama a `t1` desde otro estado, o si el bloque TON retiene su estado, podría provocar comportamientos inesperados. Lo mismo aplica a `t2` cuando se incorpore.
- **Corrección:** Llamar explícitamente a `t1(IN := FALSE)` al salir del estado `1`, o bien usar la asignación `t1(IN := estado = 1, PT := T#8S)` fuera del CASE para que el reset sea siempre explícito y controlado.

---

**Error 5 — `btnParo` no desactiva `kM`**

- **Dónde:** Bloque `IF btnParo THEN` al final del código.
- **Por qué es un error:** Al pulsar `btnParo` se desactivan `kY` y `kD`, y se resetea `estado := 0`, pero `kM` (contactor principal) permanece activado. El motor seguiría alimentado aunque se haya ordenado la parada, lo que contradice el requisito de que `btnParo` desactiva **todos** los contactores.
- **Corrección:** Añadir `kM := FALSE;` dentro del bloque `IF btnParo THEN`.