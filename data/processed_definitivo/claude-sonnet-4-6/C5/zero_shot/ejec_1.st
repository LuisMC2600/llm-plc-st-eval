# Análisis de errores lógicos en FB_EstrellaTriangulo

---

**Error 1 — Estado 1: `kD` se activa antes de desconectar `kY` (violación del enclavamiento)**

- **Dónde:** Estado `1`, dentro del bloque `IF t1.Q THEN`.
- **Por qué es un error:** En cuanto `t1.Q` se pone a `TRUE`, el código asigna `kD := TRUE` sin haber desactivado `kY` previamente. En ese mismo ciclo de scan ambas salidas están activas simultáneamente, lo que viola el requisito de que `kY` y `kD` jamás deben estar activos al mismo tiempo (riesgo de cortocircuito entre fases).
- **Corrección propuesta:** En ese mismo bloque, desactivar primero `kY` antes de pasar al estado de tiempo muerto, y no activar `kD` todavía. La activación de `kD` debe ocurrir solo después de que transcurra el tiempo muerto (ver Error 2).

---

**Error 2 — Falta el tiempo muerto de 100 ms entre la desconexión de `kY` y la conexión de `kD`**

- **Dónde:** Transición entre estados `1` y `2`; el temporizador `t2` está declarado pero nunca se usa.
- **Por qué es un error:** El requisito exige un tiempo muerto de 100 ms entre la apertura de `kY` y el cierre de `kD`. El código pasa directamente a activar `kD` (o al estado 2) sin esperar ese intervalo. El temporizador `t2` declarado en `VAR` queda completamente inutilizado.
- **Corrección propuesta:** Introducir un estado intermedio (p. ej. estado `2`) donde se desactive `kY`, se arranque `t2` con `PT := T#100MS`, y solo cuando `t2.Q = TRUE` se transite a un nuevo estado (p. ej. estado `3`) donde se active `kD`. El estado actual `2` pasaría a ser ese estado `3`.

---

**Error 3 — Estado 2: `kY := FALSE` se ejecuta repetidamente pero `kD` nunca se activa en la ruta correcta**

- **Dónde:** Estado `2`, única instrucción del bloque.
- **Por qué es un error:** Tras la corrección del Error 1, `kD` debe activarse en este estado (o en el siguiente tras el tiempo muerto). Tal como está el código original, el estado `2` solo desactiva `kY` ciclo tras ciclo sin activar `kD` ni avanzar a ningún estado estable, dejando el motor sin ningún contactor de marcha activo indefinidamente.
- **Corrección propuesta:** Una vez introducido el estado intermedio de tiempo muerto (Error 2), el estado final debe asignar `kD := TRUE` y permanecer en ese estado estable hasta que se pulse `btnParo`.

---

**Error 4 — El temporizador `t1` no se resetea al volver al estado `0`**

- **Dónde:** Bloque `IF btnParo` y estado `0`.
- **Por qué es un error:** `t1` solo se llama con `IN := TRUE` en el estado `1`. Si se pulsa `btnParo` mientras `t1` está en marcha y luego se vuelve a pulsar `btnMarcha`, el temporizador `TON` recuerda su estado interno (`ET` acumulado) del ciclo anterior porque nunca se le llama con `IN := FALSE` para reiniciarlo. Dependiendo de la implementación del runtime, podría dispararse inmediatamente o comportarse de forma impredecible en el siguiente arranque.
- **Corrección propuesta:** Llamar a `t1` con `IN := FALSE` (y análogamente `t2` con `IN := FALSE`) cuando se está en el estado `0`, o bien al procesar `btnParo`, para garantizar que ambos temporizadores queden correctamente reiniciados antes del siguiente ciclo de arranque.

---

**Error 5 — `btnParo` no desactiva `kM`**

- **Dónde:** Bloque `IF btnParo THEN` al final del código.
- **Por qué es un error:** Al pulsar paro se asigna `kY := FALSE` y `kD := FALSE`, pero `kM` (contactor principal) permanece activo. El motor seguiría alimentado aunque se haya ordenado la parada, lo que contradice el requisito de que `btnParo` desactiva **todos** los contactores.
- **Corrección propuesta:** Añadir `kM := FALSE;` dentro del bloque `IF btnParo THEN`.