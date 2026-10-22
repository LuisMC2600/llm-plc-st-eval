1. **Lógica de habilitación invertida**
   * **Sección:** Línea `IF NOT habilitado THEN`
   * **Por qué es un error:** El requerimiento establece que el semáforo cíclico debe funcionar *mientras* la variable `habilitado` esté activa (TRUE). Al usar `NOT habilitado`, el ciclo normal se ejecuta cuando el sistema está deshabilitado, lo cual es exactamente lo opuesto a lo solicitado.
   * **Corrección:** Cambiar la condición a `IF habilitado THEN`.

2. **Falta de reinicio del temporizador (`t1`) en las transiciones de estado**
   * **Sección:** Dentro de los estados `0`, `1` y `2` del `CASE` (ej. `IF t1.Q THEN estado := 1; END_IF`).
   * **Por qué es un error:** En el estándar IEC 61131-3, un temporizador `TON` necesita que su entrada `IN` pase a `FALSE` para reiniciar su tiempo acumulado y poner su salida `Q` en `FALSE`. Al cambiar de estado sin reiniciar el temporizador, la entrada `IN` se mantiene en `TRUE`, por lo que `t1.Q` seguirá siendo `TRUE`. Esto provocará que los estados subsiguientes se salten instantáneamente sin respetar los tiempos de 4s y 15s.
   * **Corrección:** Añadir la instrucción `t1(IN := FALSE);` justo antes de la asignación del nuevo estado dentro de cada condición `IF t1.Q THEN` (ej. `IF t1.Q THEN t1(IN := FALSE); estado := 1; END_IF`).

3. **El modo de amarillo intermitente es inaccesible y carece de lógica de oscilación**
   * **Sección:** Rama `ELSE` y estado `3` del `CASE`.
   * **Por qué es un error:** Cuando el semáforo pasa al modo deshabilitado (rama `ELSE`), el código simplemente apaga todas las luces (`luzV := FALSE; luzA := FALSE; luzR := FALSE;`). El estado `3` (que asigna `luzA := parp;`) nunca se alcanza porque la variable `estado` nunca se iguala a 3. Además, la variable `parp` está declarada pero no existe ninguna lógica en el código que la haga alternar entre TRUE y FALSE, por lo que siempre valdrá FALSE.
   * **Corrección:** En la rama `ELSE`, forzar el estado al modo intermitente (`estado := 3;`) o manejar las salidas directamente ahí (`luzV := FALSE; luzR := FALSE; luzA := parp;`). Adicionalmente, se debe agregar lógica fuera del `CASE` para generar el parpadeo de la variable `parp` (por ejemplo, usando una marca de reloj del sistema o un bloque `BLINK` / temporizadores en cascada).

4. **Falta de reinicio del ciclo (estado) al deshabilitar el sistema**
   * **Sección:** Rama `ELSE`.
   * **Por qué es un error:** Si la señal `habilitado` pasa a FALSE, el ciclo se interrumpe, pero la variable `estado` retiene su último valor (0, 1 o 2). Cuando el sistema se vuelva a habilitar, el semáforo reanudará su funcionamiento desde un estado intermedio y con el temporizador desfasado, en lugar de iniciar limpiamente desde el verde.
   * **Corrección:** Dentro de la rama `ELSE`, además de gestionar la luz amarilla intermitente, se debe reiniciar la máquina de estados y el temporizador agregando `estado := 0;` y `t1(IN := FALSE);` para garantizar un arranque seguro la próxima vez que se habilite.