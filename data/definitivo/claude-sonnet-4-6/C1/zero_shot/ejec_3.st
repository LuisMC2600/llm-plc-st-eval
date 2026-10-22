# Análisis de errores en FB_Semaforo

---

**Error 1 — Condición del IF principal invertida (línea `IF NOT habilitado THEN`)**

- **Dónde:** Condición principal de control.
- **Por qué es error:** La lógica está al revés. El ciclo semafórico debería ejecutarse cuando `habilitado = TRUE`, pero con `NOT habilitado` se ejecuta precisamente cuando el bloque está *deshabilitado*. Cuando `habilitado` es TRUE, se apagan todas las luces (rama ELSE), que es el comportamiento contrario al esperado.
- **Corrección:** Cambiar la condición a `IF habilitado THEN`.

---

**Error 2 — El temporizador TON nunca se reinicia entre transiciones de estado (dentro del CASE)**

- **Dónde:** Estados 0, 1 y 2 del CASE.
- **Por qué es error:** El temporizador `t1` es una instancia única. Cuando se detecta `t1.Q = TRUE` y se cambia de estado, en el siguiente ciclo el nuevo estado llama a `t1` con `IN := TRUE` y un nuevo `PT`, pero `t1.Q` sigue siendo TRUE porque `IN` nunca pasó por FALSE. El temporizador no se reinicia y la condición `t1.Q` se cumple inmediatamente en el nuevo estado, provocando transiciones instantáneas.
- **Corrección:** Al detectar la transición, poner `IN := FALSE` en una llamada previa, o bien llamar al temporizador con `IN := FALSE` durante un ciclo antes de cambiar de estado. La forma más limpia en IEC 61131-3 es llamar a `t1(IN := FALSE)` justo antes de cambiar `estado`, para que se reinicie:
  ```
  IF t1.Q THEN
      t1(IN := FALSE);   (* reinicio explícito *)
      estado := 1;
  END_IF
  ```

---

**Error 3 — En el estado 1 no se apaga `luzR` (línea del estado 1)**

- **Dónde:** `Estado 1` (fase amarilla).
- **Por qué es error:** Al entrar al estado 1 procedente del estado 2 (rojo), la salida `luzR` no se pone a FALSE explícitamente. Como las salidas son VAR retentivas entre ciclos, `luzR` permanecerá encendida junto con `luzA`, mostrando amarillo y rojo simultáneamente.
- **Corrección:** Añadir `luzR := FALSE;` en el estado 1:
  ```
  luzV := FALSE; luzA := TRUE; luzR := FALSE;
  ```

---

**Error 4 — En el estado 2 no se apaga `luzV` (línea del estado 2)**

- **Dónde:** `Estado 2` (fase roja).
- **Por qué es error:** Al entrar al estado 2 procedente del estado 1, `luzV` no se pone a FALSE. Si por alguna razón `luzV` estuviera activa, permanecería encendida junto con `luzR`.
- **Corrección:** Añadir `luzV := FALSE;` en el estado 2:
  ```
  luzV := FALSE; luzA := FALSE; luzR := TRUE;
  ```

---

**Error 5 — El estado 3 (amarillo intermitente) nunca es alcanzable**

- **Dónde:** `Estado 3` del CASE y lógica general del bloque.
- **Por qué es error:** Ningún estado del CASE ni ninguna lógica externa transiciona hacia `estado := 3`. El estado 3 está definido pero es código muerto; el modo intermitente nunca se activa.
- **Corrección:** Debe existir una entrada (por ejemplo `VAR_INPUT modoIntermitente : BOOL`) y una condición que asigne `estado := 3`, así como una condición de salida del estado 3 que regrese al ciclo normal. Además, la variable `parp` debe ser generada por un oscilador (por ejemplo otro TON o un bloque de clock), ya que actualmente nunca cambia de valor.

---

**Error 6 — La variable `parp` nunca se actualiza (estado 3)**

- **Dónde:** Estado 3 y declaración de variables.
- **Por qué es error:** `parp` se declara como `BOOL` pero nunca se le asigna ningún valor oscilante dentro del bloque. En el estado 3 se asigna `luzA := parp`, pero `parp` siempre valdrá FALSE (valor inicial por defecto), por lo que la luz amarilla nunca parpadeará.
- **Corrección:** Implementar un oscilador para `parp`, por ejemplo mediante un segundo temporizador TON que se autoalterne, o usando un bloque `BLINK` si la plataforma lo provee:
  ```
  tParp(IN := NOT tParp.Q, PT := T#500MS);
  parp := tParp.Q;
  ```