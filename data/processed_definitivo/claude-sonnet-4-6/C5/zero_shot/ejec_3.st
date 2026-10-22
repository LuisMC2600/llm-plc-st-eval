# Análisis de errores lógicos en FB_EstrellaTriangulo

---

**Error 1 — Estado 1: `kD` se activa antes de desconectar `kY` (violación del enclavamiento)**

- **Dónde:** Estado `1`, dentro del bloque `IF t1.Q THEN`.
- **Por qué es un error:** En cuanto expira el temporizador, el código hace `kD := TRUE` y salta al estado `2`, donde *después* se ejecuta `kY := FALSE`. Esto significa que durante al menos un ciclo de scan ambos contactores están activos simultáneamente, violando el requisito de que kY y kD jamás deben coincidir.
- **Corrección:** Al detectar `t1.Q`, únicamente desactivar `kY` y avanzar al estado `2` (inicio del tiempo muerto). La activación de `kD` debe ocurrir en un estado posterior, tras cumplirse el tiempo muerto.

---

**Error 2 — Estado 1: el temporizador `t1` nunca se resetea**

- **Dónde:** Estado `1`, llamada `t1(IN := TRUE, PT := T#8S)`.
- **Por qué es un error:** `IN` se mantiene siempre en `TRUE` mientras se está en el estado `1`, pero nunca se pone a `FALSE` al salir de él. En una ejecución posterior del bloque (por ejemplo, si se hace un nuevo arranque), `t1` ya habrá completado su ciclo y `t1.Q` podría ser `TRUE` desde el primer scan, saltándose los 8 segundos.
- **Corrección:** Al abandonar el estado `1` (o al entrar en el estado `0`), llamar al temporizador con `IN := FALSE` para resetearlo: `t1(IN := FALSE)`.

---

**Error 3 — Ausencia total del temporizador de tiempo muerto (`t2` nunca se usa)**

- **Dónde:** La variable `t2` está declarada pero no aparece en ninguna parte del código.
- **Por qué es un error:** El requisito exige 100 ms de tiempo muerto entre la desconexión de `kY` y la conexión de `kD`. Sin ese temporizador activo en un estado intermedio, el tiempo muerto no se implementa en absoluto.
- **Corrección:** Introducir un estado intermedio (p. ej. estado `2`) donde se ejecute `t2(IN := TRUE, PT := T#100MS)` y, solo cuando `t2.Q` sea `TRUE`, se pase a un estado `3` donde se active `kD`. El estado actual `2` pasaría a ser ese estado `3`.

---

**Error 4 — Estado 2: `kY` se desactiva tarde y de forma incompleta**

- **Dónde:** Estado `2`, instrucción `kY := FALSE`.
- **Por qué es un error:** `kY` debería desactivarse en el mismo ciclo en que expira `t1`, es decir, al final del estado `1`, no un estado después. Tal como está, hay al menos un ciclo de scan en que el programa está en estado `2` con `kD := TRUE` (asignado en el estado anterior) y `kY` todavía en `TRUE` (aún no ejecutado el estado `2`). Además, una vez ejecutado el estado `2` en el primer scan, el programa no avanza a ningún estado siguiente, por lo que `kD` queda activo pero el autómata se queda bloqueado en el estado `2` reejecutando `kY := FALSE` indefinidamente sin propósito.
- **Corrección:** Desactivar `kY` al final del estado `1` (junto con el reset de `t1`) y hacer que el estado `2` sea exclusivamente el tiempo muerto, avanzando a un estado `3` para activar `kD` y luego a un estado final estable.

---

**Error 5 — `btnParo` no desactiva `kM`**

- **Dónde:** Bloque `IF btnParo THEN` al final del código.
- **Por qué es un error:** Al pulsar paro se ponen a `FALSE` `kY` y `kD`, y se resetea `estado`, pero `kM` (el contactor principal) permanece activo. El motor seguiría alimentado, lo que contradice el requisito de que btnParo desactiva **todos** los contactores.
- **Corrección:** Añadir `kM := FALSE;` dentro del bloque `IF btnParo THEN`.