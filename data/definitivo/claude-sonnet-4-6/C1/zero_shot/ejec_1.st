# Análisis de errores en FB_Semaforo

---

**Error 1 — Condición del IF principal invertida (línea `IF NOT habilitado THEN`)**

- **Dónde:** Condición de la estructura `IF` principal.
- **Por qué es un error:** La lógica está al revés. El ciclo semafórico (CASE) se ejecuta cuando `habilitado` es `FALSE`, y las luces se apagan cuando `habilitado` es `TRUE`. Debería ser exactamente lo contrario.
- **Corrección:** Cambiar `IF NOT habilitado THEN` por `IF habilitado THEN`.

---

**Error 2 — El temporizador nunca se resetea entre estados (dentro del CASE, estados 0, 1 y 2)**

- **Dónde:** En cada rama del CASE donde se llama a `t1`.
- **Por qué es un error:** `t1` es una única instancia de `TON`. Cuando `t1.Q` se vuelve `TRUE` y se cambia de estado, en el siguiente ciclo `t1` sigue llamándose con `IN := TRUE` y `PT` posiblemente distinto, pero `ET` no se reinicia porque nunca se pone `IN := FALSE`. El temporizador no arranca de cero al entrar en un nuevo estado.
- **Corrección:** Al detectar la transición (`t1.Q = TRUE`), antes de cambiar de estado se debe llamar a `t1(IN := FALSE)` para resetear el temporizador, o bien usar una variable auxiliar de flanco/reset. Por ejemplo, en cada transición:
  ```
  t1(IN := FALSE); // resetear
  estado := <siguiente>;
  ```

---

**Error 3 — Falta apagar `luzR` al entrar al estado 0 desde el estado 2**

- **Dónde:** Estado `0` del CASE.
- **Por qué es un error:** En el estado `0` solo se asigna `luzV := TRUE; luzA := FALSE; luzR := FALSE`, lo cual es correcto en ese estado, pero en el estado `2` se activa `luzR := TRUE` y **nunca se asigna `luzA := FALSE`** en ese mismo estado 2. Si `luzA` quedó en `TRUE` desde el estado `1`, permanece así durante el estado `2` porque el estado `2` no la apaga explícitamente.
- **Corrección:** En el estado `2`, añadir la asignación explícita: `luzV := FALSE; luzA := FALSE; luzR := TRUE;`

---

**Error 4 — El estado 3 (amarillo intermitente) nunca es alcanzable**

- **Dónde:** Estado `3` del CASE y lógica general del bloque.
- **Por qué es un error:** Ningún estado transiciona hacia `estado := 3`, y no existe ninguna entrada (variable) que permita activar el modo intermitente. El estado `3` es código muerto.
- **Corrección:** Añadir una variable de entrada (p. ej. `modoIntermitente : BOOL`) y una lógica que, cuando esté activa, asigne `estado := 3` (por ejemplo, tomando prioridad sobre el ciclo normal o como condición previa al CASE).

---

**Error 5 — La variable `parp` nunca se actualiza**

- **Dónde:** Variable `parp : BOOL` usada en el estado `3`.
- **Por qué es un error:** `parp` se declara pero nunca se modifica en ninguna parte del código. El parpadeo requiere que `parp` cambie de estado periódicamente (con un temporizador o flanco de reloj). Tal como está, `luzA` permanecerá siempre en el valor inicial de `parp` (`FALSE`), sin parpadear nunca.
- **Corrección:** Implementar la oscilación de `parp` usando el propio `t1` como temporizador de ciclo, por ejemplo:
  ```
  t1(IN := TRUE, PT := T#500MS);
  IF t1.Q THEN
      parp := NOT parp;
      t1(IN := FALSE);
  END_IF
  luzV := FALSE; luzA := parp; luzR := FALSE;
  ```