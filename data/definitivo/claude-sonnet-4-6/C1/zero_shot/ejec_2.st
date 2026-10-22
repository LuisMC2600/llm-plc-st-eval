# Análisis de errores en FB_Semaforo

---

**Error 1 — Condición del IF principal invertida (línea: `IF NOT habilitado THEN`)**

**Por qué es un error:** La lógica de control del semáforo debe ejecutarse cuando `habilitado` es `TRUE`. Con `NOT habilitado`, el CASE con los estados del semáforo se ejecuta cuando el bloque está *deshabilitado*, y el apagado de luces ocurre cuando está *habilitado*. Es exactamente lo contrario a lo requerido.

**Corrección propuesta:**
```
IF habilitado THEN   (* eliminar el NOT *)
```

---

**Error 2 — El temporizador TON no se reinicia al cambiar de estado (secciones de los estados 0, 1 y 2)**

**Por qué es un error:** `t1` es una instancia única de `TON`. Cuando se cumple `t1.Q` y se cambia de estado, `IN` sigue siendo `TRUE` en la siguiente llamada (porque el nuevo estado también llama a `t1(IN := TRUE, ...)`). El temporizador nunca se pone a `FALSE` entre transiciones, por lo que `t1.Q` permanecerá `TRUE` inmediatamente en el estado siguiente, provocando que todos los estados se salten en un solo ciclo de scan.

**Corrección propuesta:** Al detectar la transición, resetear el temporizador antes de cambiar de estado:
```
IF t1.Q THEN
    t1(IN := FALSE, PT := T#20S);  (* reset *)
    estado := 1;
END_IF
```
Aplicar el mismo patrón en los estados 1 y 2.

---

**Error 3 — Estado 1: `luzR` no se apaga explícitamente (línea: `luzV := FALSE; luzA := TRUE;`)**

**Por qué es un error:** Al entrar al estado 1 (amarillo), `luzR` no se asigna a `FALSE`. Como las variables de salida retienen su valor del ciclo anterior, si se viene del estado 2 (donde `luzR := TRUE`), la luz roja permanecerá encendida simultáneamente con la amarilla.

**Corrección propuesta:**
```
luzV := FALSE; luzA := TRUE; luzR := FALSE;
```

---

**Error 4 — Estado 2: `luzV` no se apaga explícitamente (línea: `luzA := FALSE; luzR := TRUE;`)**

**Por qué es un error:** Al entrar al estado 2 (rojo), `luzV` no se asigna a `FALSE`. Si por alguna razón `luzV` estuviera activa, permanecería encendida junto con la roja.

**Corrección propuesta:**
```
luzV := FALSE; luzA := FALSE; luzR := TRUE;
```

---

**Error 5 — El estado 3 (amarillo intermitente) nunca es alcanzable**

**Por qué es un error:** Ningún estado del CASE ni ninguna condición externa asigna `estado := 3`. El estado 3 está definido pero es código muerto; el modo de amarillo intermitente requerido en la especificación nunca se activa.

**Corrección propuesta:** Añadir una entrada adicional (p. ej. `modoIntermitente : BOOL`) y una lógica que transite al estado 3 cuando corresponda:
```
(* En VAR_INPUT *)
modoIntermitente : BOOL;

(* Antes o fuera del CASE, con prioridad *)
IF modoIntermitente THEN
    estado := 3;
END_IF
```

---

**Error 6 — La variable `parp` nunca se actualiza (estado 3: `luzA := parp;`)**

**Por qué es un error:** `parp` se declara como `BOOL` pero nunca se le asigna ningún valor ni se conecta a ningún temporizador o lógica de parpadeo. Siempre valdrá `FALSE` (valor inicial por defecto), por lo que `luzA` nunca parpadeará; permanecerá apagada indefinidamente.

**Corrección propuesta:** Implementar la lógica de parpadeo con un temporizador adicional, por ejemplo:
```
(* En VAR: agregar *)
tParp : TON;

(* En estado 3: *)
tParp(IN := NOT tParp.Q, PT := T#500MS);
IF tParp.Q THEN parp := NOT parp; END_IF
luzV := FALSE; luzA := parp; luzR := FALSE;
```